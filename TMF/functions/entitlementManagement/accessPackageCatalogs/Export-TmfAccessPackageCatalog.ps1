function Export-TmfAccessPackageCatalog {
    [CmdletBinding()] Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessPackageCatalogs'
        $base = ($script:graphBaseUrl -replace '/beta$','/v1.0')
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$base/organization?`$select=displayName,id")).value
        $export = @()
        function Convert-Catalog { param($c) [ordered]@{ displayName=$c.displayName; description=$c.description; isExternallyVisible=$c.isExternallyVisible; present=$true } }
        function Get-AllCatalogs {
            $list=@();
            try { $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/catalogs?`$top=999" -ErrorAction Stop } catch { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageCatalog' -Message $_.Exception.Message; return $list }
            if ($resp.'@odata.nextLink'){ do { $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' } while ($resp.'@odata.nextLink') } else { $list += $resp.value }
            return $list
        }
        $all = Get-AllCatalogs
    }
    process {
        if ($SpecificResources){
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique
            foreach($id in $ids){ $match = $all | Where-Object displayName -eq $id; if($match){ $match | ForEach-Object { $export += Convert-Catalog $_ } } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageCatalog' -String 'TMF.Export.NotFound' -StringValues $id,$resourceName,$tenant.displayName } }
        } else { foreach($c in $all){ $export += Convert-Catalog $c } }
    }
    end {
        $emRoot = Join-Path $OutPutPath 'entitlementManagement'
        if(-not (Test-Path $emRoot)){ New-Item -Path $OutPutPath -Name 'entitlementManagement' -ItemType Directory -Force | Out-Null }
        $path = Join-Path $emRoot $resourceName; if(-not (Test-Path $path)){ New-Item -Path $emRoot -Name $resourceName -ItemType Directory -Force | Out-Null }
        $export | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $path "$resourceName.json") -Encoding utf8 -Force
    }
}
