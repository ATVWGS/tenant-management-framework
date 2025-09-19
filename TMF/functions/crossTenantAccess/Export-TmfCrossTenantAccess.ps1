function Export-TmfCrossTenantAccess {
    [CmdletBinding()]
    param(
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    Export-TmfCrossTenantAccessPolicy -OutPutPath $OutPutPath -Cmdlet $Cmdlet
    Export-TmfCrossTenantAccessDefaultSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
    Export-TmfCrossTenantAccessPartnerSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
}
