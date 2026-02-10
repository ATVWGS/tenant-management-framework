<#
.SYNOPSIS
Exports conditional access policies into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves conditional access policies (v1.0 by default; beta when -ForceBeta or when v1.0 retrieval fails) and converts them to the TMF shape. Returns objects unless -OutPath is supplied.
.PARAMETER SpecificResources
Optional list of policy IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write the export. When omitted, objects are returned instead of writing files.
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfConditionalAccessPolicy -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfConditionalAccessPolicy -SpecificResources "Policy 1","abcd-1234" | ConvertTo-Json -Depth 15
#>
function Export-TmfConditionalAccessPolicy {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'conditionalAccessPolicies'
        try {
            $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id") -ErrorAction Stop).value 
        } catch {
            $tenant = @(@{ displayName = 'Unknown'; id = '' }) 
        }
        $policiesExport = @()

        function Convert-ConditionalAccessPolicy {
            param([object]$policy)
            $obj = [ordered]@{ displayName = $policy.displayName; state = $policy.state; present = $true }
            # Local helper to resolve arrays while preserving sentinel token order
            function _ResolveWithSentinels {
                param(
                    [string[]]$Values,
                    [string[]]$Sentinels,
                    [scriptblock]$Resolver # receives array of non-sentinels; must return array in same order
                )
                if (-not $Values) {
                    return @() 
                }
                $result = @()
                $indexMap = @()
                $toResolve = @()
                for ($i = 0; $i -lt $Values.Count; $i++) {
                    $v = $Values[$i]
                    if ($Sentinels -contains $v) {
                        $result += $v
                    } else {
                        $indexMap += $i
                        $toResolve += $v
                        $result += $null
                    }
                }
                if ($toResolve.Count -gt 0) {
                    $resolved = & $Resolver $toResolve
                    if ($resolved.getType().Name -eq "String") {
                        $result = $resolved
                    }
                    else {
                        $r = 0
                        foreach ($pos in $indexMap) {
                            $result[$pos] = $resolved[$r]; $r++ 
                        }
                    }                    
                }
                return $result
            }

            if ($policy.conditions) {
                $userSentinels = @('All', 'None', 'GuestsOrExternalUsers')
                $appSentinels = @('All', 'Office365', 'MicrosoftAdminPortals')

                if ($policy.conditions.users) {
                    if ($policy.conditions.users.includeUsers) {
                        $obj.includeUsers = @()
                        $obj.includeUsers += _ResolveWithSentinels -Values $policy.conditions.users.includeUsers -Sentinels $userSentinels -Resolver { param($vals) (Resolve-User -InputReference $vals -DontFailIfNotExisting -UserPrincipalName -Cmdlet $Cmdlet) }
                    }
                    if ($policy.conditions.users.excludeUsers) {
                        $obj.excludeUsers = @()
                        $obj.excludeUsers += _ResolveWithSentinels -Values $policy.conditions.users.excludeUsers -Sentinels $userSentinels -Resolver { param($vals) (Resolve-User -InputReference $vals -DontFailIfNotExisting -UserPrincipalName -Cmdlet $Cmdlet) }
                    }
                    if ($policy.conditions.users.includeGroups) {
                        $obj.includeGroups = @()
                        $obj.includeGroups += Resolve-Group -InputReference $policy.conditions.users.includeGroups -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                    }
                    if ($policy.conditions.users.excludeGroups) {
                        $obj.excludeGroups = @()
                        $obj.excludeGroups += Resolve-Group -InputReference $policy.conditions.users.excludeGroups -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                    }
                    if ($policy.conditions.users.includeRoles) {
                        $obj.includeRoles = @()
                        $obj.includeRoles += Resolve-DirectoryRoleTemplate -InputReference $policy.conditions.users.includeRoles -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                    }
                    if ($policy.conditions.users.excludeRoles) {
                        $obj.excludeRoles = @()
                        $obj.excludeRoles += Resolve-DirectoryRoleTemplate -InputReference $policy.conditions.users.excludeRoles -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                    }
                }
                if ($policy.conditions.applications) {
                    if ($policy.conditions.applications.includeApplications) {
                        $obj.includeApplications = @()
                        $obj.includeApplications += _ResolveWithSentinels -Values $policy.conditions.applications.includeApplications -Sentinels $appSentinels -Resolver { param($vals) (Resolve-Application -InputReference $vals -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) }
                    }
                    if ($policy.conditions.applications.excludeApplications) {
                        $obj.excludeApplications = @()
                        $obj.excludeApplications += _ResolveWithSentinels -Values $policy.conditions.applications.excludeApplications -Sentinels $appSentinels -Resolver { param($vals) (Resolve-Application -InputReference $vals -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) }
                    }
                    if ($policy.conditions.applications.applicationFilter) {
                        $obj.applicationFilter = $policy.conditions.applications.applicationFilter
                    }
                    if ($policy.conditions.applications.includeAuthenticationContextClassReferences) {
                        $obj.includeAuthenticationContextClassReferences = $policy.conditions.applications.includeAuthenticationContextClassReferences
                    }
                }
                if ($policy.conditions.clientApplications) {
                    if ($policy.conditions.clientApplications.includeServicePrincipals) {
                        $obj.includeServicePrincipals = @()
                        $obj.includeServicePrincipals += _ResolveWithSentinels -Values $policy.conditions.clientApplications.includeServicePrincipals -Sentinels $appSentinels -Resolver { param($vals) (Resolve-Application -InputReference $vals -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) }
                    }
                    if ($policy.conditions.clientApplications.excludeServicePrincipals) {
                        $obj.excludeServicePrincipals = @()
                        $obj.excludeServicePrincipals += _ResolveWithSentinels -Values $policy.conditions.clientApplications.excludeServicePrincipals -Sentinels $appSentinels -Resolver { param($vals) (Resolve-Application -InputReference $vals -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) }
                    }
                    if ($policy.conditions.clientApplications.servicePrincipalFilter) {
                        $obj.servicePrincipalFilter = $policy.conditions.clientApplications.servicePrincipalFilter
                    }
                }
                if ($policy.conditions.locations) {
                    if ($policy.conditions.locations.includeLocations) {
                        $incLocs = @()
                        $raw = $policy.conditions.locations.includeLocations
                        $guidToResolve = @()
                        foreach ($loc in $raw) {
                            if ($loc -in @('All', 'AllTrusted')) {
                                $incLocs += $loc 
                            } elseif ($loc -match $script:guidRegex) {
                                $guidToResolve += $loc 
                            } else {
                                $incLocs += $loc 
                            } 
                        }
                        if ($guidToResolve.Count -gt 0) {
                            $resolved = Resolve-NamedLocation -InputReference $guidToResolve -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet; $incLocs += $resolved 
                        }
                        $obj.includeLocations = $incLocs
                    }
                    if ($policy.conditions.locations.excludeLocations) {
                        $excLocs = @()
                        $rawx = $policy.conditions.locations.excludeLocations
                        $guidToResolveX = @()
                        foreach ($loc in $rawx) {
                            if ($loc -in @('All', 'AllTrusted')) {
                                $excLocs += $loc 
                            } elseif ($loc -match $script:guidRegex) {
                                $guidToResolveX += $loc 
                            } else {
                                $excLocs += $loc 
                            } 
                        }
                        if ($guidToResolveX.Count -gt 0) {
                            $resolvedX = Resolve-NamedLocation -InputReference $guidToResolveX -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet; $excLocs += $resolvedX 
                        }
                        $obj.excludeLocations = $excLocs
                    }
                }
                if ($policy.conditions.platforms) {
                    if ($policy.conditions.platforms.includePlatforms) {
                        $obj.includePlatforms = $policy.conditions.platforms.includePlatforms 
                    }; if ($policy.conditions.platforms.excludePlatforms) {
                        $obj.excludePlatforms = $policy.conditions.platforms.excludePlatforms 
                    } 
                }
                if ($policy.conditions.clientAppTypes) {
                    $obj.clientAppTypes = $policy.conditions.clientAppTypes 
                }
                if ($policy.conditions.signInRiskLevels) {
                    $obj.signInRiskLevels = $policy.conditions.signInRiskLevels 
                }
                if ($policy.conditions.userRiskLevels) {
                    $obj.userRiskLevels = $policy.conditions.userRiskLevels 
                }
            }
            if ($policy.grantControls) {
                if ($policy.grantControls.authenticationStrength) {
                    $authStrengthName = $policy.grantControls.authenticationStrength.displayName
                    if (-not $authStrengthName -and $policy.grantControls.authenticationStrength.id) {
                        $asId = $policy.grantControls.authenticationStrength.id
                        if ($script:authStrengthCache -and $script:authStrengthCache.ContainsKey($asId)) {
                            $authStrengthName = $script:authStrengthCache[$asId] 
                        }
                        if (-not $authStrengthName) {
                            try {
                                $authStrengthName = (Invoke-MgGraphRequest -Method GET -Uri ("$graphV1/identity/conditionalAccess/authenticationStrength/policies/{0}?`$select=id,displayName" -f $asId)).displayName 
                            } catch {
                                $authStrengthName = $asId 
                            } 
                        }
                    }
                    if ($authStrengthName) {
                        $obj.authenticationStrength = $authStrengthName 
                    }
                }
                if ($policy.grantControls.termsOfUse) {
                    $ToU = @()
                    $ToU += Resolve-Agreement -InputReference $policy.grantControls.termsOfUse -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet
                    $obj.termsOfUse = $ToU
                }
                if ($policy.grantControls.operator) {
                    $obj.operator = $policy.grantControls.operator
                }
                if ($policy.grantControls.builtInControls) {
                    $obj.builtInControls = $policy.grantControls.builtInControls
                }
            }
            if ($policy.sessionControls) {
                $obj.sessionControls = [ordered]@{}
                if ($policy.sessionControls.applicationEnforcedRestrictions) {
                    $obj.sessionControls.applicationEnforcedRestrictions = $policy.sessionControls.applicationEnforcedRestrictions 
                }
                if ($policy.sessionControls.persistentBrowser) {
                    $obj.sessionControls.persistentBrowser = $policy.sessionControls.persistentBrowser 
                }
                if ($policy.sessionControls.cloudAppSecurity) {
                    $obj.sessionControls.cloudAppSecurity = $policy.sessionControls.cloudAppSecurity 
                }
                if ($policy.sessionControls.signInFrequency) {
                    $obj.sessionControls.signInFrequency = $policy.sessionControls.signInFrequency 
                }
            }
            return $obj
        }
        # Keep begin block open until after helper function declarations

        function Get-AllConditionalAccessPolicies {
            $all = @(); $usedBeta = $false
            function Get-Paged {
                param([string]$Base) $acc = @(); $uri = "$Base/identity/conditionalAccess/policies"; do {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop; if ($resp.value) {
                        $acc += $resp.value 
                    }; $uri = $resp.'@odata.nextLink' 
                } while ($uri); return $acc 
            }
            if (-not $ForceBeta) {
                try {
                    $all = Get-Paged -Base $script:graphBaseUrl1 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('v1.0 policy retrieval failed: {0}' -f $_.Exception.Message) 
                } 
            }
            if ($ForceBeta -or $all.Count -eq 0) {
                try {
                    $all = Get-Paged -Base $script:graphBaseUrlbeta; $usedBeta = $true 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('beta policy retrieval failed: {0}' -f $_.Exception.Message) 
                } 
            }
            if ($usedBeta) {
                Write-PSFMessage -Level Verbose -Message 'Returned policies via beta (v1.0 empty or ForceBeta set).' 
            } else {
                Write-PSFMessage -Level Verbose -Message 'Returned policies via v1.0.' 
            }
            return $all
        }
    }
    process {
        $policiesToConvert = @()
        if ($SpecificResources) {
            $identifiers = @(); foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $identifiers = $identifiers | Select-Object -Unique
            $allPolicies = Get-AllConditionalAccessPolicies
            foreach ($idOrName in $identifiers) {
                $match = $allPolicies | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }; if ($match) {
                    $policiesToConvert += $match 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfConditionalAccessPolicy' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                } 
            }
        } else {
            $policiesToConvert = Get-AllConditionalAccessPolicies 
        }

        if ($policiesToConvert.Count -gt 0) {
            Write-PSFMessage -Level Verbose -Message ("Starting batch pre-resolution for {0} conditional access polic(ies)" -f $policiesToConvert.Count)
            $guidRegex = $script:guidRegex
            $userIds = [System.Collections.Generic.HashSet[string]]::new(); $groupIds = [System.Collections.Generic.HashSet[string]]::new(); $spIds = [System.Collections.Generic.HashSet[string]]::new(); $locIds = [System.Collections.Generic.HashSet[string]]::new(); $agrIds = [System.Collections.Generic.HashSet[string]]::new(); $asIds = [System.Collections.Generic.HashSet[string]]::new(); $roleIds = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($p in $policiesToConvert) {
                $c = $p.conditions
                if ($c.users) {
                    foreach ($v in @($c.users.includeUsers) + @($c.users.excludeUsers)) {
                        if ($v -and $v -match $guidRegex -and $v -notin @('All', 'None', 'GuestsOrExternalUsers')) {
                            [void]$userIds.Add($v) 
                        } 
                    }
                    foreach ($v in @($c.users.includeGroups) + @($c.users.excludeGroups)) {
                        if ($v -and $v -match $guidRegex) {
                            [void]$groupIds.Add($v) 
                        } 
                    }
                    foreach ($v in @($c.users.includeRoles) + @($c.users.excludeRoles)) {
                        if ($v -and $v -match $guidRegex) {
                            [void]$roleIds.Add($v) 
                        } 
                    }
                }
                if ($c.applications) {
                    foreach ($v in @($c.applications.includeApplications) + @($c.applications.excludeApplications)) {
                        if ($v -and $v -match $guidRegex -and $v -notin @('All', 'Office365', 'MicrosoftAdminPortals')) {
                            [void]$spIds.Add($v) 
                        } 
                    } 
                }
                if ($c.locations) {
                    foreach ($v in @($c.locations.includeLocations) + @($c.locations.excludeLocations)) {
                        if ($v -and $v -match $guidRegex -and $v -notin @('All', 'AllTrusted')) {
                            [void]$locIds.Add($v) 
                        } 
                    } 
                }
                if ($p.grantControls) {
                    if ($p.grantControls.termsOfUse) {
                        foreach ($v in $p.grantControls.termsOfUse) {
                            if ($v -and $v -match $guidRegex) {
                                [void]$agrIds.Add($v) 
                            } 
                        } 
                    }; if ($p.grantControls.authenticationStrength -and $p.grantControls.authenticationStrength.id) {
                        [void]$asIds.Add($p.grantControls.authenticationStrength.id) 
                    } 
                }
            }
            # Bulk pre-populate caches using array-capable resolvers
            # Convert HashSets (or single string fallback) to unique string arrays without using .ToArray() (compat with Windows PowerShell 5.1)
            $userIds = if ($userIds -is [System.Collections.IEnumerable] -and -not ($userIds -is [string])) {
                @($userIds | Select-Object -Unique) 
            } else {
                @($userIds) 
            }
            $groupIds = if ($groupIds -is [System.Collections.IEnumerable] -and -not ($groupIds -is [string])) {
                @($groupIds | Select-Object -Unique) 
            } else {
                @($groupIds) 
            }
            $spIds = if ($spIds -is [System.Collections.IEnumerable] -and -not ($spIds -is [string])) {
                @($spIds | Select-Object -Unique) 
            } else {
                @($spIds) 
            }
            $agrIds = if ($agrIds -is [System.Collections.IEnumerable] -and -not ($agrIds -is [string])) {
                @($agrIds | Select-Object -Unique) 
            } else {
                @($agrIds) 
            }
            $locIds = if ($locIds -is [System.Collections.IEnumerable] -and -not ($locIds -is [string])) {
                @($locIds | Select-Object -Unique) 
            } else {
                @($locIds) 
            }
            $roleIds = if ($roleIds -is [System.Collections.IEnumerable] -and -not ($roleIds -is [string])) {
                @($roleIds | Select-Object -Unique) 
            } else {
                @($roleIds) 
            }

            if ($userIds.Count -gt 0) {
                try {
                    [void](Resolve-User -InputReference $userIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ("User pre-resolution warning: {0}" -f $_.Exception.Message) 
                } 
            }
            if ($groupIds.Count -gt 0) {
                try {
                    [void](Resolve-Group -InputReference $groupIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ("Group pre-resolution warning: {0}" -f $_.Exception.Message) 
                } 
            }
            if ($spIds.Count -gt 0) {
                try {
                    # Single batched prefetch using resolver array mode (-Expand populates all identifier keys into cache)
                    [void](Resolve-Application -InputReference $spIds -DontFailIfNotExisting -Expand -Cmdlet $Cmdlet)
                } catch {
                    Write-PSFMessage -Level Verbose -Message ("Application pre-resolution warning: {0}" -f $_.Exception.Message)
                }
            }
            if ($agrIds.Count -gt 0) {
                try {
                    [void](Resolve-Agreement -InputReference $agrIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ("Agreement pre-resolution warning: {0}" -f $_.Exception.Message) 
                } 
            }
            # Pre-resolve named locations in bulk to avoid per-policy calls
            if ($locIds.Count -gt 0) {
                try {
                    [void](Resolve-NamedLocation -InputReference $locIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ("NamedLocation pre-resolution warning: {0}" -f $_.Exception.Message) 
                } 
            }
            # Pre-resolve directory roles (include/excludeRoles)
            if ($roleIds.Count -gt 0) {
                try {
                    [void](Resolve-DirectoryRoleTemplate -InputReference $roleIds -DontFailIfNotExisting -DisplayName -Cmdlet $Cmdlet) 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ("DirectoryRole pre-resolution warning: {0}" -f $_.Exception.Message) 
                } 
            }
            # Authentication strength handled below
            if ($asIds.Count -gt 0) {
                if (-not $script:authStrengthCache) {
                    $script:authStrengthCache = @{} 
                }; foreach ($asid in $asIds) {
                    if (-not $script:authStrengthCache.ContainsKey($asid)) {
                        try {
                            $asObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/identity/conditionalAccess/authenticationStrength/policies/{0}?`$select=id,displayName" -f $asid); if ($asObj.id) {
                                $script:authStrengthCache[$asObj.id] = $asObj.displayName 
                            } 
                        } catch {
                            $script:authStrengthCache[$asid] = $asid 
                        } 
                    } 
                } 
            }
        }

        foreach ($policy in $policiesToConvert) {
            $policiesExport += Convert-ConditionalAccessPolicy $policy 
        }
        if (-not $OutPath) {
            return $policiesExport 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfConditionalAccessPolicy' -Message ("Exporting $($policiesExport.Count) conditional access policy(s). ForceBeta=$ForceBeta")
        if (-not $OutPath) {
            return 
        }
        if (-not (Test-Path -LiteralPath (Join-Path $OutPath $resourceName))) {
            New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
        }
        if ($policiesExport) {
            if ($Append) {
                Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $policiesExport -Append
            }
            else {
                Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $policiesExport
            }
        }
    }
}
