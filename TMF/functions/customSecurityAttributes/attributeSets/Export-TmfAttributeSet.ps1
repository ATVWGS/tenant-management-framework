function Export-TmfAttributeSet {
<#
.SYNOPSIS
Retrieves custom security attribute sets (v1.0 by default; beta with -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional list (comma separated accepted) of set IDs (display names) to filter. Wildcards allowed.
.PARAMETER OutPutPath
Root folder to write export; when omitted objects are returned.
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAttributeSet -OutPutPath C:\tmf
.EXAMPLE
Export-TmfAttributeSet -SpecificResources AttributeSet1
#>
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'attributeSets'
        $base = if ($ForceBeta) { $script:graphBaseUrl } else { ($script:graphBaseUrl -replace '/beta$','/v1.0') }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$base/organization?`$select=displayName,id")).value
        function Convert-AttributeSet { param([object]$set) [ordered]@{ displayName=$set.id; description=$set.description; maxAttributesPerSet=$set.maxAttributesPerSet; present=$true } }
        function Get-AllAttributeSets { $list=@(); try { $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/directory/attributeSets?`$top=999" -ErrorAction Stop; if($resp.'@odata.nextLink'){ do { $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' } while($resp.'@odata.nextLink') } else { $list += $resp.value } } catch { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAttributeSet' -Message ("Unable to retrieve attributeSets: {0}" -f $_.Exception.Message) }; return $list }
        $all = Get-AllAttributeSets
    }
    process {
        $export = @()
        if ($SpecificResources) { $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique; foreach ($id in $ids) { $match = $all | Where-Object { $_.id -eq $id -or $_.id -like $id }; if ($match) { foreach ($m in $match) { $export += (Convert-AttributeSet $m) } } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAttributeSet' -String 'TMF.Export.NotFound' -StringValues $id,$resourceName,$tenant.displayName } } } else { foreach ($s in $all) { $export += (Convert-AttributeSet $s) } }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAttributeSet' -Message ("Exporting {0} attribute set(s). ForceBeta={1}" -f $export.Count,$ForceBeta)
        if (-not $OutPutPath) { return $export }
    }
    end {
        if ($OutPutPath) {
            $root = Join-Path $OutPutPath 'customSecurityAttributes'
            if (-not (Test-Path $root)) { New-Item -Path $OutPutPath -Name 'customSecurityAttributes' -ItemType Directory -Force | Out-Null }
            $path = Join-Path $root $resourceName
            if (-not (Test-Path $path)) { New-Item -Path $root -Name $resourceName -ItemType Directory -Force | Out-Null }
            $export | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $path "$resourceName.json") -Encoding utf8 -Force
        }
    }
}
