function Export-TmfPolicy {
    <#
    .SYNOPSIS
        Exports all supported policy configurations from the connected tenant.
    .DESCRIPTION
        Calls the Export functions for each policy resource type and writes them under the provided OutPath.
        If OutPath is omitted, returns a hashtable with arrays per resource. Legacy alias -OutPutPath is supported (deprecated).
    .PARAMETER OutPath
        Destination root folder to write the exported configuration. When omitted, returns objects.
    .PARAMETER SpecificResources
        Optional filter by display name; applies to singleton resources as an exact match and to collections via wildcard matching.
    .EXAMPLE
        Export-TmfPolicy -OutPath "C:\Temp\tmf-config"
    .EXAMPLE
        Export-TmfPolicy | ConvertTo-Json -Depth 15
    #>

    [CmdletBinding()]
    param(
        [Alias('OutPutPath')] [string] $OutPath,
        [string[]] $SpecificResources,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $results = @{}
    }
    process {
        Write-TmfDeprecatedParameterWarning -InvocationLine $MyInvocation.Line -LegacyParameter 'OutPutPath' -NewParameter 'OutPath'
        $exporters = @(
            { Export-TmfAuthenticationFlowsPolicy -OutPath $OutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfAuthenticationMethodsPolicy -OutPath $OutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfAuthorizationPolicy -OutPath $OutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfAppManagementPolicy -OutPath $OutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfTenantAppManagementPolicy -OutPath $OutPath -Cmdlet $Cmdlet },
            { Export-TmfAuthenticationStrengthPolicy -OutPath $OutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet }
        )
        if (-not $OutPath) {
            $results.authenticationFlowsPolicies = & $exporters[0]
            $results.authenticationMethodsPolicies = & $exporters[1]
            $results.authorizationPolicies = & $exporters[2]
            $results.appManagementPolicies = & $exporters[3]
            $results.tenantAppManagementPolicy = & $exporters[4]
            $results.authenticationStrengthPolicies = & $exporters[5]
            return $results
        } else {
            foreach ($exp in $exporters) {
                & $exp | Out-Null
            }
        }
    }
    end {
    }
}
