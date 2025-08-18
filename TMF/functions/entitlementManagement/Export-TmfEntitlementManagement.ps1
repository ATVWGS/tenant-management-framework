function Export-TmfEntitlementManagement {
    [CmdletBinding()] Param(
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin { Test-GraphConnection -Cmdlet $Cmdlet }
    process {
        Export-TmfAccessPackageCatalog -OutPutPath $OutPutPath -Cmdlet $Cmdlet
        Export-TmfAccessPackage -OutPutPath $OutPutPath -Cmdlet $Cmdlet
        Export-TmfAccessPackageAssignmentPolicy -OutPutPath $OutPutPath -Cmdlet $Cmdlet
        Export-TmfAccessPackageResource -OutPutPath $OutPutPath -Cmdlet $Cmdlet
    }
    end {}
}