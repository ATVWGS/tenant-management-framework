function Export-TmfCrossTenantAccess {
    [CmdletBinding()]
    param(
        [string]$OutPutPath,
        [switch] $Append,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    if ($Append) {
        Export-TmfCrossTenantAccessPolicy -OutPutPath $OutPutPath -Cmdlet $Cmdlet -Append
        Export-TmfCrossTenantAccessDefaultSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
        Export-TmfCrossTenantAccessPartnerSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet -Append    
    }
    else {
        Export-TmfCrossTenantAccessPolicy -OutPutPath $OutPutPath -Cmdlet $Cmdlet
        Export-TmfCrossTenantAccessDefaultSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
        Export-TmfCrossTenantAccessPartnerSetting -OutPutPath $OutPutPath -Cmdlet $Cmdlet
    }    
}
