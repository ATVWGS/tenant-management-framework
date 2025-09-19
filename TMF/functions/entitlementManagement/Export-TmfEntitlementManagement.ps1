function Export-TmfEntitlementManagement {
    [CmdletBinding()] param(
        [Alias('OutPutPath')] [string] $OutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet; $results = @{} 
    }
    process {
        if ($OutPath) {
            Export-TmfAccessPackageCatalog -OutPath $OutPath -Cmdlet $Cmdlet | Out-Null
            Export-TmfAccessPackage -OutPath $OutPath -Cmdlet $Cmdlet | Out-Null
            Export-TmfAccessPackageAssignmentPolicy -OutPath $OutPath -Cmdlet $Cmdlet | Out-Null
            Export-TmfAccessPackageResource -OutPath $OutPath -Cmdlet $Cmdlet | Out-Null
        } else {
            $results.accessPackageCatalogs = Export-TmfAccessPackageCatalog -OutPath $null -Cmdlet $Cmdlet
            $results.accessPackages = Export-TmfAccessPackage -OutPath $null -Cmdlet $Cmdlet
            $results.accessPackageAssignmentPolicies = Export-TmfAccessPackageAssignmentPolicy -OutPath $null -Cmdlet $Cmdlet
            $results.accessPackageResource = Export-TmfAccessPackageResource -OutPath $null -Cmdlet $Cmdlet
            return $results
        }
    }
    end {
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath' 
        } 
    }
}
