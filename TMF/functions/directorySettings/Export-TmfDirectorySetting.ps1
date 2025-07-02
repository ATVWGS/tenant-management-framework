function Export-TmfDirectorySetting {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'directorySettings'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        $directorySettingsExport = @()
        $templates = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directorySettingTemplates").value
        function Convert-Value {
            param(
                [string] $Value,
                [string] $Type
            )
            if ($null -eq $Value) { return $null }

            switch ($Type) {
                'Bool' { return [System.Convert]::ToBoolean($Value) }
                'Boolean' { return [System.Convert]::ToBoolean($Value) }
                'Int' { return [int] $Value }
                'Int32' { return [int] $Value }
                'Int64' { return [int64] $Value }
                'Integer' { return [int] $Value }
                default {
                    # Fallback conversion when template type information is missing
                    if ($Value -match '^(?i:true|false)$') {
                        return [System.Convert]::ToBoolean($Value)
                    } elseif ($Value -match '^[-]?\d+$') {
                        return [int] $Value
                    }
                    return $Value
                }
            }
        }
        function Convert-DirectorySetting {
            param([object]$Setting)
            $template = $templates | Where-Object { $_.id -eq $Setting.templateId }
            $export = [ordered]@{
                displayName = $Setting.displayName
                present     = $true
            }
            foreach ($tVal in $template.values) {
                $current = $Setting.values | Where-Object { $_.name -eq $tVal.name }
                if ($current) {
                    $export[$tVal.name] = Convert-Value -Value $current.value -Type $tVal.type
                }
            }
            return $export
        }
    }
    process {
        function Get-AllSettings {
            $list = @()
            $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/settings?`$top=999"
            if ($resp.keys -contains '@odata.nextLink') {
                do {
                    $list += $resp.value
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink'
                } while ($resp.'@odata.nextLink')
            } else {
                $list += $resp.value
            }
            return $list
        }

        if ($SpecificResources) {
            $identifiers = @()
            foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $identifiers = $identifiers | Select-Object -Unique
            $allSettings = Get-AllSettings

            foreach ($idOrName in $identifiers) {
                $match = $allSettings | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) {
                        $detail = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/settings/$($m.id)"
                        if ($detail) { $directorySettingsExport += Convert-DirectorySetting $detail }
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfDirectorySetting' -String 'TMF.Export.NotFound' -StringValues $idOrName,$resourceName,$tenant.displayName
                }
            }
        } else {
            $all = Get-AllSettings
            foreach ($s in $all) { $directorySettingsExport += Convert-DirectorySetting $s }
        }
    }
    end {
        if (-not (Test-Path "$OutPutPath/$($resourceName)")) {
            New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force | Out-Null
        }
        $directorySettingsExport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutPutPath/$($resourceName)/$($resourceName).json" -Encoding utf8 -Force
    }
}