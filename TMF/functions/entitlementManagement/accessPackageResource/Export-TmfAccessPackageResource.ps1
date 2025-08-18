function Export-TmfAccessPackageResource {
<#
.SYNOPSIS
Retrieves entitlement management access package resources (v1.0 by default; beta with -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional list (comma separated accepted) of display names or originIds to filter. Wildcards allowed.
.PARAMETER OutPutPath
Root folder to write export; when omitted objects are returned.
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAccessPackageResource -OutPutPath C:\tmf
.EXAMPLE
Export-TmfAccessPackageResource -SpecificResources "Catalog A - group-id"
#>
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessPackageResource'
        $base = if ($ForceBeta) { $script:graphBaseUrl } else { ($script:graphBaseUrl -replace '/beta$','/v1.0') }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$base/organization?`$select=displayName,id")).value
        $all = @()
        function Convert-Resource { param([object]$catalog,[object]$r) [ordered]@{ displayName = ("{0} - {1}" -f $catalog.displayName,$r.originId); catalog=$catalog.displayName; resourceIdentifier=$r.originId; resourceType=$r.originSystem; present=$true } }
        function Get-AllResources { param() $agg=@(); try { $catalogs = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/catalogs?`$top=999" -ErrorAction Stop } catch { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageResource' -Message $_.Exception.Message; return $agg }; $catalogList = @(); if ($catalogs.'@odata.nextLink'){ do { $catalogList += $catalogs.value; $catalogs = Invoke-MgGraphRequest -Method GET -Uri $catalogs.'@odata.nextLink' } while ($catalogs.'@odata.nextLink') } else { $catalogList += $catalogs.value }; foreach($c in $catalogList){ try { $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/catalogs/$($c.id)/resources?`$top=999" -ErrorAction Stop } catch { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageResource' -Message ("Catalog {0}: {1}" -f $c.displayName,$_.Exception.Message); continue }; $list=@(); if ($resp.'@odata.nextLink'){ do { $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' } while ($resp.'@odata.nextLink') } else { $list += $resp.value }; foreach($r in $list){ $agg += (Convert-Resource -catalog $c -r $r) } }; return $agg }
        $all = Get-AllResources
    }
    process {
        $export = @()
        if ($SpecificResources) { $filters = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ }; $filters = $filters | Select-Object -Unique; foreach ($f in $filters) { $match = $all | Where-Object { $_.displayName -eq $f -or $_.resourceIdentifier -eq $f -or $_.displayName -like $f }; if ($match) { $export += $match } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageResource' -String 'TMF.Export.NotFound' -StringValues $f,$resourceName,$tenant.displayName } } } else { $export = $all }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessPackageResource' -Message ("Exporting {0} access package resource(s). ForceBeta={1}" -f $export.Count,$ForceBeta)
        if (-not $OutPutPath) { return $export }
    }
    end {
        if ($OutPutPath) {
            $emRoot = Join-Path $OutPutPath 'entitlementManagement'
            if (-not (Test-Path $emRoot)) { New-Item -Path $OutPutPath -Name 'entitlementManagement' -ItemType Directory -Force | Out-Null }
            $path = Join-Path $emRoot $resourceName
            if (-not (Test-Path $path)) { New-Item -Path $emRoot -Name $resourceName -ItemType Directory -Force | Out-Null }
            $export | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $path "$resourceName.json") -Encoding utf8 -Force
        }
    }
}
