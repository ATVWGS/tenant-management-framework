function Export-TmfAccessPackageCatalog {
    [CmdletBinding()] param(
        [string[]]$SpecificResources,
        [Alias('OutPutPath')] [string]$OutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessPackageCatalogs'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id")).value
        $export = @()
        function Convert-Catalog {
            param($c) [ordered]@{ displayName = $c.displayName; description = $c.description; isExternallyVisible = $c.isExternallyVisible; present = $true } 
        }
        function Get-AllCatalogs {
            $list = @()
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$($script:graphBaseUrl1)/identityGovernance/entitlementManagement/catalogs?`$top=999" -ErrorAction Stop 
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageCatalog' -Message $_.Exception.Message; return $list 
            }
            if ($resp.'@odata.nextLink') {
                do {
                    $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } while ($resp.'@odata.nextLink') 
            } else {
                $list += $resp.value 
            }
            return $list
        }
        $all = Get-AllCatalogs
    }
    process {
        if ($SpecificResources) {
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique
            foreach ($id in $ids) {
                $match = $all | Where-Object displayName -EQ $id; if ($match) {
                    $match | ForEach-Object { $export += Convert-Catalog $_ } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageCatalog' -String 'TMF.Export.NotFound' -StringValues $id, $resourceName, $tenant.displayName 
                } 
            }
        } else {
            foreach ($c in $all) {
                $export += Convert-Catalog $c 
            } 
        }
    }
    end {
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath' 
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export
        } else {
            return $export 
        }
    }
}
