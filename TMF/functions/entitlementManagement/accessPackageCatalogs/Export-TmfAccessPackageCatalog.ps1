<#
.SYNOPSIS
Exports access package catalogs into TMF configuration.
.DESCRIPTION
Retrieves access package catalogs and outputs TMF objects. Returns objects unless -OutPutPath supplied.
.PARAMETER SpecificResources
Optional list of setting IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAccessPackageCatalog -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfAccessPackageCatalog -SpecificResources CatalogName
#>
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
        if ($OutPath) {
            if ($export) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export
                }
            }            
        } 
        else {
            return $export 
        }
    }
}
