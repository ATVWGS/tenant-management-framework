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
            foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.ExportFunction -and $_.Value.parentType -eq "policies" } | Sort-Object {$_.Value.weight})) {
				& $resourceType.Value["ExportFunction"] -OutPath $OutPath -Append -Cmdlet $PSCmdlet
			}			
		}
        else {
            foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.ExportFunction -and $_.Value.parentType -eq "policies" } | Sort-Object {$_.Value.weight})) {
				& $resourceType.Value["ExportFunction"] -OutPath $OutPath -Cmdlet $PSCmdlet
			}
        }
    }
    end {}
}
