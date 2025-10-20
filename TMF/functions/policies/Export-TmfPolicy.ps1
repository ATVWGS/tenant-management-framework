<#
.SYNOPSIS
Exports all supported policy configurations from the connected tenant.
.DESCRIPTION
Calls the Export functions for each policy resource type and writes them under the provided OutPath.
If OutPath is omitted, returns a hashtable with arrays per resource. Legacy alias -OutPutPath is supported (deprecated).
.PARAMETER OutPath
Destination root folder to write the exported configuration. When omitted, returns objects.
.PARAMETER Append
Add content to an existing file
.EXAMPLE
Export-TmfPolicy -OutPath "C:\Temp\tmf-config"
.EXAMPLE
Export-TmfPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfPolicy {
    
    [CmdletBinding()]
    param(
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
    }
    process {
        if ($Append) {
            Export-TmfAuthenticationFlowsPolicy -OutPath $OutPath -Append -Cmdlet $Cmdlet
            Export-TmfAuthenticationMethodsPolicy -OutPath $OutPath -Append -Cmdlet $Cmdlet
            Export-TmfAuthorizationPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfAppManagementPolicy -OutPath $OutPath -Append -Cmdlet $Cmdlet
            Export-TmfTenantAppManagementPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfAuthenticationStrengthPolicy -OutPath $OutPath -Append -Cmdlet $Cmdlet
        }
        else {
            Export-TmfAuthenticationFlowsPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfAuthenticationMethodsPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfAuthorizationPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfAppManagementPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfTenantAppManagementPolicy -OutPath $OutPath -Cmdlet $Cmdlet
            Export-TmfAuthenticationStrengthPolicy -OutPath $OutPath -Cmdlet $Cmdlet
        }
    }
    end {
    }
}
