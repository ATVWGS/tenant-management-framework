<#
.SYNOPSIS
    Exports app management policies from the tenant.
.DESCRIPTION
    Retrieves appManagementPolicies collection from Microsoft Graph and converts them
    into the TMF desired configuration shape. Writes to policies/appManagementPolicies/appManagementPolicies.json
    when OutPutPath is provided, or returns the objects when omitted.
.PARAMETER SpecificResources
    Optional filter by display name. Can include wildcards; matches are applied client-side.
.PARAMETER OutPath
    Destination root folder to write the exported configuration. (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to an existing file
.PARAMETER Cmdlet
    The invoking cmdlet. Defaults to the current $PSCmdlet.
.EXAMPLE
    Export-TmfAppManagementPolicy -OutPath "C:\Temp\tmf-config"
.EXAMPLE
    Export-TmfAppManagementPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfAppManagementPolicy {
    
    [CmdletBinding()]
    param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'appManagementPolicies'
        $parentName = 'policies'

        function Convert-AppManagementPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy,
                [string[]] $appliesToIds
            )
            $obj = [ordered]@{ present = $true }
            foreach ($p in @('id', 'displayName', 'description', 'isEnabled')) {
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p -and $policy.$p -ne '') {
                    $obj[$p] = $policy.$p
                }
            }
            if ($policy.PSObject.Members.Match('restrictions') -and $null -ne $policy.restrictions) {
                $obj.restrictions = $policy.restrictions
            }
            if ($appliesToIds -and $appliesToIds.Count -gt 0) {
                $obj.appliesTo = $appliesToIds
            }
            return [pscustomobject]$obj
        }

        function Get-AllAppManagementPolicies {
            $all = @(); $usedBeta = $false
            $v1Uri = "$script:graphBaseUrl1/policies/appManagementPolicies"
            $resp = $null
            if (-not $ForceBeta) {
                try {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $v1Uri
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('v1.0 appManagementPolicies retrieval failed: {0}' -f $_.Exception.Message)
                }
            }
            if ($ForceBeta -or -not $resp) {
                try {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/policies/appManagementPolicies"; $usedBeta = $true
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('beta appManagementPolicies retrieval failed: {0}' -f $_.Exception.Message)
                }
            }
            if (-not $resp) {
                return @()
            }
            do {
                if ($resp.value) {
                    $all += $resp.value
                }; $next = $resp.'@odata.nextLink'; if ($next) {
                    try {
                        $resp = Invoke-MgGraphRequest -Method GET -Uri $next
                    } catch {
                        Write-PSFMessage -Level Verbose -Message ('Pagination fetch failed: {0}' -f $_.Exception.Message); break
                    }
                }
            } while ($next)
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAppManagementPolicy' -Message ("Retrieved {0} appManagementPolicies (UsedBeta={1} ForceBeta={2})" -f $all.Count, $usedBeta, $ForceBeta)
            return $all
        }
    }
    process {
        $policies = Get-AllAppManagementPolicies
        if (-not $policies) {
            if (-not $OutPath) {
                return @()
            } else {
                $export = @()
            }
        }
        if ($SpecificResources) {
            $filters = @()
            foreach ($entry in $SpecificResources) {
                $filters += ($entry -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $filters = $filters | Select-Object -Unique
            $policies = $policies | Where-Object { $name = $_.displayName; ($filters | Where-Object { $name -like $_ }).Count -gt 0 }
        }
        $export = @()
        foreach ($p in $policies) {
            # Get appliesTo for each policy (ids)
            $appliesToIds = @()
            try {
                $rel = Invoke-MgGraphRequest -Method GET -Uri ("{0}/policies/appManagementPolicies/{1}/appliesTo" -f (if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }), $p.id)
                if ($rel.value) {
                    $appliesToIds = $rel.value.id
                }
            } catch {
                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAppManagementPolicy' -Message "Failed to fetch appliesTo for policy $($p.id): $_"
            }
            $export += (Convert-AppManagementPolicy -policy $p -appliesToIds $appliesToIds)
        }
    }
    end {
        if (-not $OutPath) {
            return $export
        }
        if ($export) {
            if ($Append) {
                Write-TmfExportFile -OutPath $OutPath -ParentPath $parentName -ResourceName $resourceName -Data $export -Append
            }
            else {
                Write-TmfExportFile -OutPath $OutPath -ParentPath $parentName -ResourceName $resourceName -Data $export
            }
        }        
    }
}
