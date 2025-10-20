<#
.SYNOPSIS
Exports authentication strength policies into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves authentication strength policies from Microsoft Graph (v1.0 by default; beta when -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied.
.PARAMETER SpecificResources
Optional list of policy display names (wildcards allowed) to filter.
.PARAMETER OutPath
Root folder to write the export. When omitted, objects are returned instead of writing files.
.PARAMETER Append
Add content to an existing file
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAuthenticationStrengthPolicy -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfAuthenticationStrengthPolicy -SpecificResources "*MFA*" | ConvertTo-Json -Depth 15
#>
function Export-TmfAuthenticationStrengthPolicy {
    
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'authenticationStrengthPolicies'
        $parentName = 'policies'

        function Convert-AuthenticationStrengthPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy
            )
            $obj = [ordered]@{ present = $true }
            foreach ($p in @('id', 'displayName', 'description', 'policyType', 'allowedCombinations')) {
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p) {
                    $obj[$p] = $policy.$p 
                }
            }
            if ($policy.PSObject.Members.Match('combinationConfigurations') -and $null -ne $policy.combinationConfigurations) {
                $obj.combinationConfigurations = $policy.combinationConfigurations
            }
            return [pscustomobject]$obj
        }

        function Get-AllAuthenticationStrengthPolicies {
            $all = @()
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/policies/authenticationStrengthPolicies?`$filter=policyType ne 'builtIn'" 
            } catch {
                throw $_ 
            }
            if ($resp.'@odata.nextLink') {
                do {
                    if ($resp.value) {
                        $all += $resp.value 
                    }
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink'
                } while ($resp.'@odata.nextLink')
            }
            if ($resp.value) {
                $all += $resp.value 
            }
            return $all
        }
    }
    process {
        $policies = Get-AllAuthenticationStrengthPolicies
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
            $export += (Convert-AuthenticationStrengthPolicy -policy $p) 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationStrengthPolicy' -Message "Exporting $($export.Count) authentication strength policy(s). ForceBeta=$ForceBeta"
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
