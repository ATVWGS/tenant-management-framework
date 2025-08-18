function Export-TmfCustomSecurityAttributeAllowedValue {
<#
.SYNOPSIS
Exports allowed values for custom security attribute definitions.
.DESCRIPTION
Fetches customSecurityAttributeDefinitions and their allowed values; merges them into the definitions export (single source of truth). Returns objects when -OutPutPath is omitted.
.PARAMETER SpecificResources
Optional filter: value id or "<definitionId>_<valueId>" (comma separated accepted).
.PARAMETER OutPutPath
Root folder for output.
.PARAMETER ForceBeta
Use beta Graph endpoint.
.PARAMETER EmitStandalone
Also emit legacy standalone allowed values JSON file (otherwise it is removed).
.EXAMPLE
Export-TmfCustomSecurityAttributeAllowedValue -OutPutPath C:\config
.EXAMPLE
Export-TmfCustomSecurityAttributeAllowedValue -OutPutPath C:\config -EmitStandalone
#>
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
    [switch] $EmitStandalone,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'customSecurityAttributeAllowedValues'
        $base = if ($ForceBeta) { $script:graphBaseUrl } else { ($script:graphBaseUrl -replace '/beta$','/v1.0') }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$base/organization?`$select=displayName,id")).value
        $export = @()
        function Convert-AllowedValue { param([object]$v,[string]$attributeId) [ordered]@{ displayName = ("{0}_{1}" -f $attributeId,$v.id); id=$v.id; attributeId=$attributeId; isActive=$v.isActive; present=$true } }
        $definitions = @()
        try {
            $defsResp = Invoke-MgGraphRequest -Method GET -Uri "$base/directory/customSecurityAttributeDefinitions?`$top=999" -ErrorAction Stop
            if ($defsResp.'@odata.nextLink') { do { $definitions += $defsResp.value; $defsResp = Invoke-MgGraphRequest -Method GET -Uri $defsResp.'@odata.nextLink' } while ($defsResp.'@odata.nextLink') } else { $definitions += $defsResp.value }
        } catch {
            Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message "Unable to retrieve definitions: $($_.Exception.Message)"
        }
        $all = @()
        foreach ($def in $definitions) {
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri ("$base/directory/customSecurityAttributeDefinitions/{0}/allowedValues?`$top=999" -f [System.Web.HttpUtility]::UrlEncode($def.id))
                $vals = @()
                if ($resp.'@odata.nextLink') { do { $vals += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' } while ($resp.'@odata.nextLink') } else { $vals += $resp.value }
                foreach ($val in $vals) { $all += [pscustomobject]@{ definition=$def; value=$val } }
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message "Failed to get allowed values for definition $($def.id): $($_.Exception.Message)"
            }
        }
        Set-Variable -Name '_tmf_csattr_definitions' -Value $definitions -Scope Local
        Set-Variable -Name '_tmf_csattr_all' -Value $all -Scope Local
    }
    process {
        $all = Get-Variable -Name '_tmf_csattr_all' -Scope Local -ValueOnly
        if ($SpecificResources) {
            $filters = @(); foreach ($e in $SpecificResources) { $filters += $e -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }; $filters = $filters | Select-Object -Unique
            foreach ($f in $filters) {
                $match = $all | Where-Object { ("{0}_{1}" -f $_.definition.id,$_.value.id) -eq $f -or $_.value.id -eq $f }
                if ($match) { foreach ($m in $match) { $export += Convert-AllowedValue $m.value $m.definition.id } } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -String 'TMF.Export.NotFound' -StringValues $f,$resourceName,$tenant.displayName }
            }
        } else {
            foreach ($entry in $all) { $export += Convert-AllowedValue $entry.value $entry.definition.id }
        }
    Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message ("Exporting {0} allowed value(s). ForceBeta={1}" -f $export.Count,$ForceBeta)
        if (-not $OutPutPath) { return $export }
    }
    end {
        if ($OutPutPath) {
            $root = Join-Path $OutPutPath 'customSecurityAttributes'
            if (-not (Test-Path $root)) { New-Item -Path $OutPutPath -Name 'customSecurityAttributes' -ItemType Directory -Force | Out-Null }
            $avPath = Join-Path $root $resourceName
            $legacyFile = Join-Path $avPath "$resourceName.json"
            if ($EmitStandalone) {
                if (-not (Test-Path $avPath)) { New-Item -Path $root -Name $resourceName -ItemType Directory -Force | Out-Null }
                ($export | ConvertTo-Json -Depth 15) | Out-File -FilePath $legacyFile -Encoding utf8 -Force
                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message 'Standalone allowed values file emitted (legacy compatibility).'
            } else {
                if (Test-Path $legacyFile) {
                    try { Remove-Item -Path $legacyFile -Force -ErrorAction Stop; Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message 'Removed legacy standalone allowed values file to enforce single source of truth.' } catch { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message "Failed to remove legacy standalone file: $($_.Exception.Message)" }
                }
            }
            $definitionsDir = Join-Path $root 'customSecurityAttributeDefinitions'
            if (-not (Test-Path $definitionsDir)) { New-Item -Path $root -Name 'customSecurityAttributeDefinitions' -ItemType Directory -Force | Out-Null }
            $definitionsFile = Join-Path $definitionsDir 'customSecurityAttributeDefinitions.json'
            $definitionsFromFile = $null
            if (Test-Path $definitionsFile) {
                try {
                    $raw = Get-Content -Path $definitionsFile -Raw -ErrorAction Stop
                    if ($raw.Trim()) { $definitionsFromFile = $raw | ConvertFrom-Json -ErrorAction Stop } else { $definitionsFromFile = @() }
                } catch {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message "Failed to parse existing definitions file; recreating. Error: $($_.Exception.Message)"
                    $definitionsFromFile = $null
                }
            }
            $graphDefs = Get-Variable -Name '_tmf_csattr_definitions' -Scope Local -ValueOnly
            if (-not $definitionsFromFile) { $definitionsFromFile = @() }
            if ($definitionsFromFile -isnot [System.Collections.IEnumerable]) { $definitionsFromFile = @($definitionsFromFile) }
            $index = @{}
            foreach ($d in $definitionsFromFile) { if ($d.displayName) { $index[$d.displayName] = $d } }
            foreach ($gdef in $graphDefs) {
                $id = $gdef.id
                if (-not $index.ContainsKey($id)) {
                    $new = [pscustomobject]@{
                        displayName             = $id
                        description             = $gdef.description
                        attributeSet            = $gdef.attributeSet
                        name                    = $gdef.name
                        isCollection            = $gdef.isCollection
                        isSearchable            = $gdef.isSearchable
                        status                  = $gdef.status
                        type                    = $gdef.type
                        usePreDefinedValuesOnly = $gdef.usePreDefinedValuesOnly
                        allowedValues           = @()
                        present                 = $true
                    }
                    $definitionsFromFile += $new
                    $index[$id] = $new
                }
            }
            foreach ($def in $index.Keys) { $index[$def].allowedValues = @() }
            foreach ($val in $export) {
                if ($index.ContainsKey($val.attributeId)) {
                    $index[$val.attributeId].allowedValues += [pscustomobject]@{ displayName = $val.id; isActive = $val.isActive }
                }
            }
            foreach ($def in $index.Values) { $def.allowedValues = @($def.allowedValues | Sort-Object -Property displayName -Unique) }
            $definitionsFromFile = @($index.Values | Sort-Object -Property displayName)
            ($definitionsFromFile | ConvertTo-Json -Depth 15) | Out-File -FilePath $definitionsFile -Encoding utf8 -Force
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCustomSecurityAttributeAllowedValue' -Message ("Merged allowedValues into definitions file ({0} definitions)." -f $definitionsFromFile.Count)
        }
    }
}
