<#
.SYNOPSIS
Wrapper export for custom security attribute related resources.
.DESCRIPTION
Invokes the individual exporters for attribute sets, definitions and allowed values. Passes -ForceBeta flag to each when provided. Does not aggregate output; use individual exporters for object return values.
.PARAMETER OutPutPath
Root folder to write export; when omitted underlying exporters return objects individually (this wrapper returns nothing).
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCustomSecurityAttribute -OutPutPath C:\temp\tmf
#>
function Export-TmfCustomSecurityAttribute {
    [CmdletBinding()] Param(
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin { Test-GraphConnection -Cmdlet $Cmdlet }
    process {
        Export-TmfAttributeSet -OutPutPath $OutPutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
        Export-TmfCustomSecurityAttributeDefinition -OutPutPath $OutPutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
        Export-TmfCustomSecurityAttributeAllowedValue -OutPutPath $OutPutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
    }
    end {}
}
