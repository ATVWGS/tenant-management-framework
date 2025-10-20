function Export-TmfAttributeSet {
    <#
.SYNOPSIS
Retrieves custom security attribute sets (v1.0 by default; beta with -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied. (Legacy alias: -OutPutPath)
.PARAMETER SpecificResources
Optional list (comma separated accepted) of set IDs (display names) to filter. Wildcards allowed.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAttributeSet -OutPath C:\tmf
.EXAMPLE
Export-TmfAttributeSet -SpecificResources AttributeSet1
#>
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'attributeSets'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id")).value
        function Convert-AttributeSet {
            param([object]$set) [ordered]@{ displayName = $set.id; description = $set.description; maxAttributesPerSet = $set.maxAttributesPerSet; present = $true } 
        }
        function Get-AllAttributeSets {
            $list = @(); $apiBase = if ($ForceBeta) {
                $script:graphBaseUrlbeta 
            } else {
                $script:graphBaseUrl1 
            }; try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/directory/attributeSets?`$top=999" -ErrorAction Stop; if ($resp.'@odata.nextLink') {
                    do {
                        $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                    } while ($resp.'@odata.nextLink') 
                } else {
                    $list += $resp.value 
                } 
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAttributeSet' -Message ("Unable to retrieve attributeSets: {0}" -f $_.Exception.Message) 
            }; return $list 
        }
        $all = Get-AllAttributeSets
    }
    process {
        $export = @()
        if ($SpecificResources) {
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique; foreach ($id in $ids) {
                $match = $all | Where-Object { $_.id -eq $id -or $_.id -like $id }; if ($match) {
                    foreach ($m in $match) {
                        $export += (Convert-AttributeSet $m) 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAttributeSet' -String 'TMF.Export.NotFound' -StringValues $id, $resourceName, $tenant.displayName 
                } 
            } 
        } else {
            foreach ($s in $all) {
                $export += (Convert-AttributeSet $s) 
            } 
        }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAttributeSet' -Message ("Exporting {0} attribute set(s). ForceBeta={1}" -f $export.Count, $ForceBeta)
        if (-not $OutPath) {
            return $export 
        }
    }
    end {
        if ($OutPath) {
            <#$root = Join-Path $OutPath 'customSecurityAttributes'
            if (-not (Test-Path $root)) {
                New-Item -Path $OutPath -Name 'customSecurityAttributes' -ItemType Directory -Force | Out-Null 
            }
            $path = Join-Path $root $resourceName
            if (-not (Test-Path $path)) {
                New-Item -Path $root -Name $resourceName -ItemType Directory -Force | Out-Null 
            }##>
            if ($export) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'customSecurityAttributes' -ResourceName $resourceName -Data $export -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'customSecurityAttributes' -ResourceName $resourceName -Data $export -Append
                }
            }
            #$export | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $path "$resourceName.json") -Encoding utf8 -Force
        }
    }
}
