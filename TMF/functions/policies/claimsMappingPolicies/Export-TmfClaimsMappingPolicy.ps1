<#
.SYNOPSIS
    Exports claims mapping policies from the tenant.
.DESCRIPTION
    Retrieves claimsMappingPolicies collection from Microsoft Graph and converts them
    into the TMF desired configuration shape. Writes to policies/claimsMappingPolicies/claimsMappingPolicies.json
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
    Export-TmfClaimsMappingPolicy -OutPath "C:\Temp\tmf-config"
.EXAMPLE
    Export-TmfClaimsMappingPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfClaimsMappingPolicy {
    
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
        $resourceName = 'claimsMappingPolicies'
        $parentName = 'policies'

        function Convert-ClaimsMappingPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy
            )
            $obj = [ordered]@{ present = $true }
            foreach ($p in @('displayName', 'definition', 'isOrganizationDefault')) {
                if ($policy.$p -and $null -ne $policy.$p -and $policy.$p -ne '') {
                    $obj[$p] = $policy.$p
                }
            }
            if ($policy.appliesTo) {
                $obj.appliesTo = @()
                foreach ($SPN in $policy.appliesTo) {
                    $obj.appliesTo += $SPN.displayName
                }
            }
            else {
                $obj.appliesTo = @()
            }
            return [pscustomobject]$obj
        }

        function Get-AllClaimsMappingPolicies {
            $all = @(); $usedBeta = $false
            $v1Uri = "$script:graphBaseUrl1/policies/claimsMappingPolicies?`$expand=appliesTo"
            $resp = $null
            if (-not $ForceBeta) {
                try {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $v1Uri
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('v1.0 claimsMappingPolicies retrieval failed: {0}' -f $_.Exception.Message)
                }
            }
            if ($ForceBeta -or -not $resp) {
                try {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/policies/claimsMappingPolicies?`$expand=appliesTo"; $usedBeta = $true
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('beta claimsMappingPolicies retrieval failed: {0}' -f $_.Exception.Message)
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
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfClaimsMappingPolicy' -Message ("Retrieved {0} claimsMappingPolicies (UsedBeta={1} ForceBeta={2})" -f $all.Count, $usedBeta, $ForceBeta)
            return $all
        }
    }
    process {
        $policies = Get-AllClaimsMappingPolicies
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
            $export += (Convert-ClaimsMappingPolicy -policy $p)
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
