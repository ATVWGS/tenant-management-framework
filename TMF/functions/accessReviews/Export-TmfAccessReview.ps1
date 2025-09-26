<#
.SYNOPSIS
Exports access review definitions.
.DESCRIPTION
Retrieves access review schedule definitions from Microsoft Graph (v1.0 by default; beta with -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied (writes to accessReviews/accessReviews.json). Legacy alias -OutPutPath is deprecated.
.PARAMETER SpecificResources
Optional list of access review IDs or display names (comma separated accepted) to filter.
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
#>
function Export-TmfAccessReview {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
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
        $filterIdSet = [System.Collections.Generic.HashSet[string]]::new()
        $filterNameSet = [System.Collections.Generic.HashSet[string]]::new()
        if ($SpecificResources) {
            $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique | ForEach-Object {
                if ($_ -match $script:guidRegex) {
                    [void]$filterIdSet.Add($_) 
                } else {
                    [void]$filterNameSet.Add($_) 
                }
            }
        }
        if ($OutPath) {
            if (-not (Test-Path -LiteralPath (Join-Path $OutPath $resourceName))) {
                New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
            }
            $jsonFilePath = (Join-Path (Join-Path $OutPath $resourceName) "$resourceName.json")
            # Create/overwrite file and write opening bracket for JSON array
            $streamWriter = [System.IO.StreamWriter]::new($jsonFilePath, $false, [System.Text.UTF8Encoding]::new($false))
            if (-not $JsonLines) {
                $streamWriter.Write('[') 
            }
            $streaming = $true
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
                }
                if (-not $principalId -and $rev.query -match '/users/([0-9a-fA-F\-]{36})') {
                    $principalId = $rev.query.split("/")[3]
                }
                if (-not $principalId) {
                    continue 
                }
                $type = if ($rev.query -and $rev.query -match '/transitiveMembers') {
                    'groupMembers' 
                } else {
                    'singleUser' 
                }
                $out += [pscustomobject]@{ type = $type; reference = $principalId }
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
                $simple.type = 'group'
                if ($SkipScopeNameLookup) {
                    $simple.reference = $groupId 
                } elseif ($groupNameCache.ContainsKey($groupId)) {
                    $simple.reference = $groupNameCache[$groupId] 
                } else {
                    $simple.reference = $groupId 
                } # fallback if not yet resolved
            } elseif ($roleId) {
                $simple.type = 'directoryRole'
                if ($SkipScopeNameLookup) {
                    $simple.reference = $roleId 
                } elseif ($roleNameCache.ContainsKey($roleId)) {
                    $simple.reference = $roleNameCache[$roleId] 
                } else {
                    $simple.reference = $roleId 
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
                $obj.scope = (Resolve-ScopeDisplayName -Scope $Review.scope) 
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
            [pscustomobject]$obj
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
            foreach ($rev in @($buffer)) {
                $converted = Convert-AccessReview $rev
                if ($streaming) {
                    $json = $converted | ConvertTo-Json -Depth 15 -Compress
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
                    $accessReviewsExport += $converted 
                }
            }
            $buffer.Clear()
        }
    }
    process {
        GetAccessReviewPageData 
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
            Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $accessReviewsExport
        }
    }
}
