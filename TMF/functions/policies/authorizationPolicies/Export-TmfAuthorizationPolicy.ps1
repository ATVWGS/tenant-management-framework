function Export-TmfAuthorizationPolicy {
    <#
    .SYNOPSIS
    Retrieves the singleton authorizationPolicy (v1.0 by default; beta when -ForceBeta or v1.0 unsupported) and converts it to the TMF shape. Returns object unless -OutPath is supplied.
    .PARAMETER SpecificResources
    Optional filter by display name (wildcards). Singleton; typically omitted.
    .PARAMETER OutPath
    Root folder to write export; when omitted the object is returned.
    .PARAMETER ForceBeta
    Always use beta endpoint (or fallback when v1.0 fails/insufficient).
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfAuthorizationPolicy -OutPath C:\tmf
    .EXAMPLE
    Export-TmfAuthorizationPolicy | ConvertTo-Json -Depth 15
    #>

    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'authorizationPolicies'
        $parentName = 'policies'
        function Convert-AuthorizationPolicy {
            param([object]$policy) $o = [ordered]@{ present = $true }; if ($policy.displayName) {
                $o.displayName = $policy.displayName
            }; foreach ($p in 'allowInvitesFrom', 'allowedToSignUpEmailBasedSubscriptions', 'allowedToUseSSPR', 'allowEmailVerifiedUsersToJoinOrganization', 'blockMsolPowerShell', 'guestUserRole', 'allowedToCreateApps', 'allowedToCreateSecurityGroups', 'allowedToReadOtherUsers', 'allowedToReadBitlockerKeysForOwnedDevice', 'permissionGrantPolicyIdsAssignedToDefaultUserRole') {
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p) {
                    $o[$p] = $policy.$p
                }
            }; if ($policy.defaultUserRolePermissions) {
                $durp = $policy.defaultUserRolePermissions; foreach ($prop in $durp.PSObject.Properties) {
                    if ($prop.Name -ne '@odata.type' -and $null -ne $prop.Value) {
                        $o[$prop.Name] = $prop.Value
                    }
                }
            }; [pscustomobject]$o
        }
    }
    process {
        $policy = $null; $usedBeta = $false
        if (-not $ForceBeta) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl1/policies/authorizationPolicy"
            } catch {
                Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message)
            }
        }
        if ($ForceBeta -or -not $policy) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrlbeta/policies/authorizationPolicy"; $usedBeta = $true
            } catch {
                Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message)
            }
        }
        if (-not $policy) {
            if (-not $OutPutPath) {
                return @()
            } else {
                return
            }
        }
        $exportObject = Convert-AuthorizationPolicy $policy
        if ($SpecificResources) {
            $filters = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ }; if (($filters | Where-Object { $exportObject.displayName -like $_ }).Count -eq 0 -and ($filters -notcontains '*')) {
                if (-not $OutPutPath) {
                    return @()
                } else {
                    return
                }
            }
        }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthorizationPolicy' -Message ("Exporting authorization policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta, $usedBeta)
    }
    end {
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath'
        }
        if (-not $OutPath) {
            return @($exportObject)
        }
        Write-TmfExportFile -OutPath $OutPath -ParentPath $parentName -ResourceName $resourceName -Data @($exportObject)
    }
}
