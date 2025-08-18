function Export-TmfPolicy {
    <#
        .SYNOPSIS
            Exports all supported policy configurations from the connected tenant.

        .DESCRIPTION
            Calls the Export functions for each policy resource type and writes them under the provided OutPutPath.
            If OutPutPath is omitted, returns a hashtable with arrays per resource.

        .PARAMETER OutPutPath
            Destination root folder to write the exported configuration. When omitted, returns objects.

        .PARAMETER SpecificResources
            Optional filter by display name; applies to singleton resources as an exact match and to collections via wildcard matching.

        .EXAMPLE
            Export-TmfPolicy -OutPutPath "C:\Temp\tmf-config"

        .EXAMPLE
            Export-TmfPolicy | ConvertTo-Json -Depth 15
    #>
    [CmdletBinding()]
    Param(
        [string] $OutPutPath,
        [string[]] $SpecificResources,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $results = @{}
    }
    process {
        $exporters = @(
            { Export-TmfAuthenticationFlowsPolicy -OutPutPath $OutPutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfAuthenticationMethodsPolicy -OutPutPath $OutPutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfAuthorizationPolicy -OutPutPath $OutPutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfAppManagementPolicy -OutPutPath $OutPutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet },
            { Export-TmfTenantAppManagementPolicy -OutPutPath $OutPutPath -Cmdlet $Cmdlet },
            { Export-TmfAuthenticationStrengthPolicy -OutPutPath $OutPutPath -SpecificResources $SpecificResources -Cmdlet $Cmdlet }
        )

        if (-not $OutPutPath) {
            $results.authenticationFlowsPolicies = & $exporters[0]
            $results.authenticationMethodsPolicies = & $exporters[1]
            $results.authorizationPolicies = & $exporters[2]
            $results.appManagementPolicies = & $exporters[3]
            $results.tenantAppManagementPolicy = & $exporters[4]
            $results.authenticationStrengthPolicies = & $exporters[5]
            return $results
        }
        else {
            foreach ($exp in $exporters) { & $exp | Out-Null }
        }
    }
    end {}
}
