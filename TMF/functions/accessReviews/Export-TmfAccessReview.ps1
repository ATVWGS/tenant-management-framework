<#
.SYNOPSIS
Exports access review definitions.
.DESCRIPTION
Retrieves access review schedule definitions from Microsoft Graph (v1.0 by default; beta with -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied (writes to accessReviews/accessReviews.json). Legacy alias -OutPutPath is deprecated.
.PARAMETER SpecificResources
Optional list of access review IDs or display names (comma separated accepted) to filter.
.PARAMETER groups
Optional list of group IDs, displaynames or wildcards, e.g. "MyGroupNames*" (finds all groups, whose displayname contains "MyGroupNames" and uses them to gather accessReviews on these groups)
.PARAMETER OutPath
Root folder to write the export. When omitted, objects are returned. Legacy alias -OutPutPath is accepted (deprecated).
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAccessReview -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfAccessReview -SpecificResources "Review 1","abcd-1234" | ConvertTo-Json -Depth 15
.EXAMPLE
Export-TmfAccessReview -SpecificResources "ca314f7f-9bec-4914-ab25-c1fc936c739b","Review 2" -groups "ca219f7f-9bec-4914-ab25-c1fc936c739f","MyDistinctGroupName", "MyGroupNamePrefix*" -OutPath C:\temp\tmf
#>
function Export-TmfAccessReview {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [string[]] $groups,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [switch] $Append,
        [int] $PageSize = 999, # user-requested, internally capped to 100 by API
        [switch] $SkipScopeNameLookup,
        [int] $BatchResolveSize = 50,
        [int] $MaxRetry = 5,
        [int] $InitialRetrySeconds = 2,
        [int] $MaxDefinitions,              # optional: stop after N processed (useful for sampling / test runs)
        [int] $TimeoutMinutes,              # optional: stop after elapsed minutes
        [switch] $JsonLines,                # write one JSON object per line (no surrounding array) for safer partial/interrupted runs
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessReviews'
        $graphBase = if ($ForceBeta) {
            $script:graphBaseUrl 
        } else {
            $script:graphBaseUrl1 
        }
        $tenantMeta = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id")).value
        $accessReviewsExport = @()
        $streaming = $false
        $jsonFilePath = $null
        $streamWriter = $null
        $firstWrite = $true
        $global:bufferedFirstWrite = $true
        $totalExpected = $null
        $lastPercent = -1
        $terminatedEarly = $false
        $terminationReason = $null
        $startTime = Get-Date
        # Caches & batching structures
        $groupNameCache = @{}
        $roleNameCache = @{}
        $groupPending = [System.Collections.Generic.HashSet[string]]::new()
        $rolePending = [System.Collections.Generic.HashSet[string]]::new()
        $buffer = New-Object System.Collections.ArrayList
        # Prepare SpecificResources filters
        $filterIDs = @()
        $filterNames = @()
        if ($SpecificResources) {
            $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique | ForEach-Object {
                if ($_ -match $script:guidRegex) {
                    $filterIDs += $_
                } else {
                    $filterNames += $_
                }
            }
        }
        if ($groups) {
            $groupIDs = @()
            $groupNames = @()
            $groupSearches = @()

            foreach ($group in $groups) {
                if ($group -match $script:guidRegex) {
                    $groupIDs += $group
                }
                elseif ($group -match "\*") {
                    $groupSearches += $group.replace("*","")
                }
                else {
                    $groupNames += $group
                }
            }
        }
        if ($OutPath) {
            if (-not (Test-Path -LiteralPath (Join-Path $OutPath $resourceName))) {
                New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
            }
            $jsonFilePath = (Join-Path (Join-Path $OutPath $resourceName) "$resourceName.json")
            # Create/overwrite file and write opening bracket for JSON array
            if ((-not $SpecificResources) -and (-not $groups)) {
                $streamWriter = [System.IO.StreamWriter]::new($jsonFilePath, $false, [System.Text.UTF8Encoding]::new($false))
                if (-not $JsonLines) {
                    $streamWriter.Write('[') 
                }
                $streaming = $true
            }            
        }

        function Convert-ReviewerList {
            param([object[]]$List)
            if (-not $List) {
                return @() 
            }
            $out = @()
            foreach ($rev in $List) {
                if (-not $rev) {
                    continue 
                }
                $principalId = $rev.principalId
                if (-not $principalId -and $rev.query -match '/groups/([0-9a-fA-F\-]{36})') {
                    $principalId = $rev.query.split("/")[3]
                    Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Resolving group $principalId"
                    $reference = Resolve-Group -InputReference $principalId -DisplayName -DontFailIfNotExisting -Cmdlet $Cmdlet
                    if ($reference -eq $principalId) {
                        $reference = "NotFound"
                    }
                }
                if (-not $principalId -and $rev.query -match '/users/([0-9a-fA-F\-]{36})') {
                    $principalId = $rev.query.split("/")[3]
                    Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Resolving user $principalId"
                    $reference = Resolve-User -InputReference $principalId -Userprincipalname -DontFailIfNotExisting -Cmdlet $Cmdlet
                    if ($reference -eq $principalId) {
                        $reference = "NotFound"
                    }
                }
                if (-not $principalId) {
                    continue 
                }
                $type = if ($rev.query -and $rev.query -match '/transitiveMembers') {
                    'groupMembers' 
                } elseif ($rev.query -and $rev.query -match '/owners') {
                    'owners'
                } else {
                    'singleUser' 
                }
                $out += [pscustomobject]@{ type = $type; reference = $reference }
            }
            return $out
        }
        function Resolve-ScopeDisplayName {
            param([object]$Scope)
            if (-not $Scope) {
                return $null 
            }
            $simple = [ordered]@{}
            $query = $Scope.query
            $roleId = $null; $groupId = $null
            if ($query -match "/groups/([0-9a-fA-F\-]{36})") {
                $groupId = $matches[1] 
            }
            if ($query -match "uniqueRoleId='([0-9a-fA-F\-]{36})'") {
                $roleId = $matches[1] 
            }
            if ($groupId) {
                if ($Scope.query -match "userType eq 'Guest'") {
                    $simple.type = 'groupGuests'
                }
                else {
                    $simple.type = 'group'
                }                
                if ($SkipScopeNameLookup) {
                    $simple.reference = $groupId 
                } elseif ($groupNameCache.ContainsKey($groupId)) {
                    $simple.reference = $groupNameCache[$groupId] 
                } else {
                    $simple.reference = Resolve-Group -InputReference $groupId -DisplayName -DontFailIfNotExisting
                    if ($simple.reference -eq $groupId -or (-not $simple.reference)) {
                        $simple.reference = "NotFound"
                    }
                } # fallback if not yet resolved
            } elseif ($roleId) {
                $simple.type = 'directoryRole'
                if ($SkipScopeNameLookup) {
                    $simple.reference = $roleId 
                } elseif ($roleNameCache.ContainsKey($roleId)) {
                    $simple.reference = $roleNameCache[$roleId] 
                } else {
                    try {
                        $simple.reference = Resolve-DirectoryRoleTemplate -InputReference $roleId -DisplayName -DontFailIfNotExisting
                        if ($simple.reference -eq $roleId -or (-not $simple.reference)) {
                            $simple.reference = "NotFound"
                        }
                    }
                    catch {
                        $simple.reference = "NotFound"
                    }                    
                }
                $simple.subScope = if ($query -match 'servicePrincipal') {
                    'servicePrincipals' 
                } else {
                    'users_groups' 
                }
            } else {
                if ($Scope.type) {
                    $simple.type = $Scope.type 
                }
                if ($Scope.reference) {
                    $simple.reference = $Scope.reference 
                }
            }
            return $simple
        }
        function Convert-AccessReview {
            param([object]$Review)
            $obj = [ordered]@{ displayName = $Review.displayName; present = $true }
            # include all @odata.* properties
            foreach ($p in $Review.PSObject.Properties) {
                if ($p.Name -like '@odata*') {
                    $obj[$p.Name] = $p.Value 
                } 
            }
            if ($Review.description) {
                $obj.description = $Review.description 
            }
            if ($Review.scope) {
                switch ($Review.scope."@odata.type") {
                    "#microsoft.graph.accessReviewQueryScope" {
                        if ($Review.scope.query -match "/groups" -or $Review.scope.query -match "uniqueRoleId") {
                            $obj.scope = (Resolve-ScopeDisplayName -Scope $Review.scope)
                        }
                        else {
                            $obj.scope = $Review.scope
                        }                        
                    }
                    "#microsoft.graph.principalResourceMembershipsScope" {
                        $obj.scope = $Review.scope
                    }
                }
            }
            if ($Review.reviewers) {
                $obj.reviewers = (Convert-ReviewerList -List $Review.reviewers) 
            }
            if ($Review.fallbackReviewers) {
                $obj.fallbackReviewers = (Convert-ReviewerList -List $Review.fallbackReviewers) 
            }
            if ($Review.settings) {
                $obj.settings = $Review.settings 
            }
            if ($obj.scope.reference -match $script:guidRegex -or $obj.scope.reference -eq "NotFound" -or (-not $obj.scope) -or $obj.reviewers.reference -contains "NotFound" -or (-not $obj.reviewers)) {
                Write-PSFMessage -Level Verbose -Message "Access review $($obj.displayname) skipped due to unresolvable scope or reviewers."
            }
            else {
                [pscustomobject]$obj
            }            
        }
        function Invoke-GraphWithRetry {
            param([string]$Uri, [hashtable]$Headers)
            $attempt = 0; $delay = $InitialRetrySeconds
            while ($true) {
                try {
                    return Invoke-MgGraphRequest -Method GET -Uri $Uri -Headers $Headers 
                } catch {
                    $attempt++
                    $status = $_.Exception.Response.StatusCode.value__ 2>$null
                    $isThrottle = ($status -eq 429 -or $status -eq 503 -or $status -eq 504)
                    if (-not $isThrottle -or $attempt -ge $MaxRetry) {
                        throw 
                    }
                    Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Throttle/Retry attempt $attempt for $Uri (status $status). Sleeping $delay s."; Start-Sleep -Seconds $delay; $delay = [Math]::Min($delay * 2, 120)
                }
            }
        }
        # Legacy alias placeholder (removed hyphenated name to satisfy analyzer)
        function GetAccessReviewPageData {
            $requested = if ($PageSize -gt 0) {
                $PageSize 
            } else {
                100 
            }
            if ($requested -gt 100) {
                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Requested PageSize $requested exceeds API max 100; capping."; $requested = 100 
            }
            $topParam = "$requested"
            $baseParams = "`$top=$topParam"
            $countUri = "$graphBase/identityGovernance/accessReviews/definitions?$baseParams&`$count=true"
            $headers = @{ }
            try {
                $headers['ConsistencyLevel'] = 'eventual'
                $firstResp = Invoke-GraphWithRetry -Uri $countUri -Headers $headers
                if ($firstResp.'@odata.count') {
                    $global:__accessReviewTotal = $firstResp.'@odata.count'; $script:__accessReviewFirstPage = $firstResp 
                }
            } catch {
                $headers.Remove('ConsistencyLevel') 2>$null 
            }
            if (-not $script:__accessReviewFirstPage) {
                $script:__accessReviewFirstPage = Invoke-GraphWithRetry -Uri "$graphBase/identityGovernance/accessReviews/definitions?$baseParams" -Headers $headers 
            }
            $totalExpected = $global:__accessReviewTotal
            $page = 0; $processed = 0
            $resp = $script:__accessReviewFirstPage
            while ($true) {
                $page++
                foreach ($item in @($resp.value)) {
                    # Early termination checks (timeout / max definitions)
                    if ($TimeoutMinutes -and ((Get-Date) - $startTime).TotalMinutes -ge $TimeoutMinutes) {
                        $terminatedEarly = $true; $terminationReason = "Timeout ($TimeoutMinutes minute limit reached)"; break 
                    }
                    # Filter resources if specified
                    if ($filterIdSet.Count -gt 0 -or $filterNameSet.Count -gt 0) {
                        $match = $false
                        if ($filterIdSet.Count -gt 0 -and $item.id -and $filterIdSet.Contains($item.id)) {
                            $match = $true 
                        } elseif ($filterNameSet.Count -gt 0 -and $item.displayName -and $filterNameSet.Contains($item.displayName)) {
                            $match = $true 
                        }
                        if (-not $match) {
                            continue 
                        }
                    }
                    if ($MaxDefinitions -and $processed -ge $MaxDefinitions) {
                        $terminatedEarly = $true; $terminationReason = "MaxDefinitions ($MaxDefinitions) reached"; break 
                    }
                    $processed++
                    # Extract scope IDs for later batch resolution
                    if (-not $SkipScopeNameLookup -and $item.scope -and $item.scope.query) {
                        $q = $item.scope.query
                        if ($q -match "/groups/([0-9a-fA-F\-]{36})" ) {
                            $gid = $matches[1]; if (-not $groupNameCache.ContainsKey($gid)) {
                                [void]$groupPending.Add($gid) 
                            } 
                        }
                        if ($q -match "uniqueRoleId='([0-9a-fA-F\-]{36})'") {
                            $rid = $matches[1]; if (-not $roleNameCache.ContainsKey($rid)) {
                                [void]$rolePending.Add($rid) 
                            } 
                        }
                    }
                    # Buffer review
                    [void]$buffer.Add($item)
                    if ($buffer.Count -ge $BatchResolveSize) {
                        Write-BufferedAccessReviews 
                    }
                    if ($totalExpected) {
                        $pct = [int](($processed / $totalExpected) * 100)
                        if ($pct -ne $lastPercent -and ($pct % 5) -eq 0) {
                            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Progress: $processed / $totalExpected ($pct%)"; $lastPercent = $pct 
                        }
                    } elseif (($processed % 5000) -eq 0) {
                        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Processed $processed definitions..." 
                    }
                }
                if ($terminatedEarly) {
                    break 
                }
                $next = $resp.'@odata.nextLink'
                if (-not $next) {
                    break 
                }
                $resp = Invoke-GraphWithRetry -Uri $next -Headers $headers
            }
            # flush remainder
            Write-BufferedAccessReviews
        }
        function Write-BufferedAccessReviews {
            if ($buffer.Count -eq 0) {
                return 
            }
            Write-PSFMessage -Level Verbose -Message "BufferedFirstWrite: $global:bufferedFirstWrite"
            # Lazy create writer if streaming somehow enabled but writer not initialized (safety net)
            if ($streaming -and -not $streamWriter) {
                if (-not (Test-Path -LiteralPath (Join-Path $OutPath $resourceName))) {
                    New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
                }
                $jsonFilePath = (Join-Path (Join-Path $OutPath $resourceName) "$resourceName.json")
                $streamWriter = [System.IO.StreamWriter]::new($jsonFilePath, $false, [System.Text.UTF8Encoding]::new($false))
                if ($firstWrite -and -not $JsonLines) {
                    $streamWriter.Write('[') 
                } # ensure opening bracket if not written
            }
            if ($global:bufferedFirstWrite) {
                $global:bufferedFirstWrite = $false
            }
            else {
                $streamWriter.Write(",`n") 
            }
            if (-not $SkipScopeNameLookup) {
                if ($groupPending.Count -gt 0) {
                    $groupIds = @($groupPending)
                    try {
                        $resolvedGroups = Resolve-Group -InputReference $groupIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                        for ($i = 0; $i -lt $groupIds.Count; $i++) {
                            $gid = $groupIds[$i]; $dn = $resolvedGroups[$i]; if ($dn -and $dn -ne $gid) {
                                $groupNameCache[$gid] = $dn 
                            } else {
                                $groupNameCache[$gid] = $gid 
                            } 
                        }
                    } catch {
                        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Group batch resolve warning: $($_.Exception.Message)" 
                    }
                    $groupPending.Clear()
                }
                if ($rolePending.Count -gt 0) {
                    $roleIds = @($rolePending)
                    try {
                        $resolvedRoles = Resolve-DirectoryRoleTemplate -InputReference $roleIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                        for ($i = 0; $i -lt $roleIds.Count; $i++) {
                            $rid = $roleIds[$i]; $dn = $resolvedRoles[$i]; if ($dn -and $dn -ne $rid) {
                                $roleNameCache[$rid] = $dn 
                            } else {
                                $roleNameCache[$rid] = $rid 
                            } 
                        }
                    } catch {
                        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Role batch resolve warning: $($_.Exception.Message)" 
                    }
                    $rolePending.Clear()
                }
            }
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Firstwrite: $firstWrite"
            foreach ($rev in @($buffer)) {
                $converted = Convert-AccessReview $rev
                if ($streaming -and $converted) {
                    $json = $converted | ConvertTo-Json -Depth 15
                    if ($JsonLines) {
                        if (-not $firstWrite) {
                            $streamWriter.Write("`n") 
                        }
                        $streamWriter.Write($json)
                    } else {
                        if (-not $firstWrite) {
                            $streamWriter.Write(",`n") 
                        }
                        $streamWriter.Write($json)
                    }
                    $firstWrite = $false
                    $streamWriter.Flush()  # ensure on-disk frequently to reduce loss risk on interruption
                } else {
                    if ($converted) {
                        $accessReviewsExport += $converted 
                    }                    
                }
            }
            $streamWriter.Flush()
            $buffer.Clear()
        }
        function GetFilteredAccessReviews {
            param (
                [string[]]$filterIDs,
                [string[]]$filterNames,
                [string[]]$groupIDs,
                [string[]]$groupNames,
                [string[]]$groupSearches
            )
            $accessReviewsExport = @()
            $filteredReviewResults = @()
            if ($filterIDs) {
                foreach ($id in $filterIDs) {
                    $filteredReviewResults += Invoke-MgGraphRequest -Method GET -Uri "$graphBase/identityGovernance/accessReviews/definitions/$($id)"
                }
            }
            if ($filterNames) {
                foreach ($name in $filterNames) {
                    $filteredReviewResults += (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/identityGovernance/accessReviews/definitions?`$filter=displayname eq '$($name)'").value
                }
            }
            if ($groupIDs) {
                foreach ($groupId in $groupIDs) {
                    $filteredReviewResults += (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/identityGovernance/accessReviews/definitions?`$filter=contains(scope/microsoft.graph.accessReviewQueryScope/query, '/groups/$($groupId)')").value
                }
            }
            if ($groupNames) {
                $resolvedGroupIDs = Resolve-Group -InputReference $groupNames -DontFailIfNotExisting -SearchInDesiredConfiguration
                foreach ($groupId in $resolvedGroupIDs) {
                    $filteredReviewResults += (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/identityGovernance/accessReviews/definitions?`$filter=contains(scope/microsoft.graph.accessReviewQueryScope/query, '/groups/$($groupId)')").value
                }
            }
            if ($groupSearches) {
                $resolvedGroupSearchIDs = foreach ($search in $groupSearches) {(Invoke-MgGraphRequest -Method GET -Uri "$graphBase/groups?`$search=`"displayName:$($search)`"&`$top=999&`$select=id" -Headers @{"ConsistencyLevel"="eventual"}).value.id}
                foreach ($groupId in $resolvedGroupSearchIDs) {
                    $filteredReviewResults += (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/identityGovernance/accessReviews/definitions?`$filter=contains(scope/microsoft.graph.accessReviewQueryScope/query, '/groups/$($groupId)')").value
                }
            }

            foreach ($review in $filteredReviewResults) {
                $accessReviewsExport += Convert-AccessReview -Review $review
            }
            return $accessReviewsExport
        }
    }
    process {
        if ($SpecificResources -or $Groups) {
            $accessReviewsExport = GetFilteredAccessReviews -filterIDs $filterIDs -filterNames $filterNames -groupIDs $groupIDs -groupNames $groupNames -groupSearches $groupSearches
        }
        else {
            if ($Append -and $OutPath) {
                Write-PSFMessage -Level Warning -Message "Switch -Append is only supported for filtered exports (SpecificResources,Groups). File $OutPath will be overwritten!"
            }
            GetAccessReviewPageData 
        }        
    }
    end {
        if ($streaming) {
            if (-not $JsonLines) {
                $streamWriter.Write(']') 
            }
            $streamWriter.Flush(); $streamWriter.Dispose()
            if ($terminatedEarly) {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessReview' -Message "Export terminated early: $terminationReason. File: $jsonFilePath (partial output) Tenant: $($tenantMeta.displayName)"
            } else {
                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Completed streaming export to $jsonFilePath for tenant $($tenantMeta.displayName)"
            }
        } else {
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessReview' -Message "Exporting $($accessReviewsExport.Count) access review(s). ForceBeta=$ForceBeta PageSize=$PageSize"
            if (-not $OutPath) {
                return $accessReviewsExport 
            }
            # Use central helper for non-stream writes
            if ($accessReviewsExport) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $accessReviewsExport -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $accessReviewsExport
                }
            }
            else {
                Write-PSFMessage -Level Warning -Message "No access review data found to export."
            }
        }
    }
}
