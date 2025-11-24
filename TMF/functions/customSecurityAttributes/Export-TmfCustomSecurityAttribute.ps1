<#
.SYNOPSIS
Wrapper export for custom security attribute related resources.
.DESCRIPTION
Invokes the individual exporters for attribute sets, definitions and allowed values. Passes -ForceBeta flag to each when provided. Does not aggregate output; use individual exporters for object return values.
.PARAMETER OutPath
Root folder to write export; when omitted underlying exporters return objects individually (this wrapper returns nothing). (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCustomSecurityAttribute -OutPath C:\temp\tmf
#>
function Export-TmfCustomSecurityAttribute {
    [CmdletBinding()] param(
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
    }
    process {
        if ($Append) {
            Export-TmfAttributeSet -OutPath $OutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet -Append
            Export-TmfCustomSecurityAttributeDefinition -OutPath $OutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet -Append
            Export-TmfCustomSecurityAttributeAllowedValue -OutPath $OutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
        }
        else {
            Export-TmfAttributeSet -OutPath $OutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
            Export-TmfCustomSecurityAttributeDefinition -OutPath $OutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
            Export-TmfCustomSecurityAttributeAllowedValue -OutPath $OutPath -ForceBeta:$ForceBeta.IsPresent -Cmdlet $Cmdlet
        }
        
    }
    end {
    }
}
