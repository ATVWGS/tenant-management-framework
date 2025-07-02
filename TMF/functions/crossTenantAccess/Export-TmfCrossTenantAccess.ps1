function Export-TmfCrossTenantAccess {
    [CmdletBinding()]
    Param(
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    Export-TmfCrossTenantAccessPolicy -OutPutPath $OutPutPath -Cmdlet $Cmdlet
    Export-TmfCrossTenantAccessDefaultSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
    Export-TmfCrossTenantAccessPartnerSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
}