function Export-TmfEntitlementManagement {
    [CmdletBinding()] param(
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet; $results = @{} 
    }
    process {
        if ($OutPath) {
            if ($Append) {
                Export-TmfAccessPackageCatalog -OutPath $OutPath -Cmdlet $Cmdlet -Append | Out-Null
                Export-TmfAccessPackage -OutPath $OutPath -Cmdlet $Cmdlet -Append | Out-Null
            }
            else {
                Export-TmfAccessPackageCatalog -OutPath $OutPath -Cmdlet $Cmdlet | Out-Null
                Export-TmfAccessPackage -OutPath $OutPath -Cmdlet $Cmdlet | Out-Null
            }
            
        } else {
            $results.accessPackageCatalogs = Export-TmfAccessPackageCatalog -OutPath $null -Cmdlet $Cmdlet
            $results.accessPackages = Export-TmfAccessPackage -OutPath $null -Cmdlet $Cmdlet
            return $results
        }
    }
    end {
    }
}
