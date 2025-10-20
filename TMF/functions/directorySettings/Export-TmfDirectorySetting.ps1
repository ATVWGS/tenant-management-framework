<#
.SYNOPSIS
Exports directory settings (template-based) into TMF configuration.
.DESCRIPTION
Retrieves directory settings, merges with template metadata to cast values, and outputs TMF objects. Returns objects unless -OutPutPath supplied.
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
Export-TmfDirectorySetting -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfDirectorySetting -SpecificResources Group.Unified
#>
function Export-TmfDirectorySetting {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta = $true,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'directorySettings'
        $graphBase = if ($ForceBeta) {
            $script:graphBaseUrl 
        } else {
            $script:graphBaseUrl1 
        }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $directorySettingsExport = @()
        $templates = (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/directorySettingTemplates").value
        function Convert-Value {
            param([string]$Value, [string]$Type) if ($null -eq $Value) {
                return $null 
            }; switch ($Type) {
                'Bool' {
                    return [bool]$Value 
                } 'Boolean' {
                    return [bool]$Value 
                } 'Int' {
                    return [int]$Value 
                } 'Int32' {
                    return [int]$Value 
                } 'Int64' {
                    return [int64]$Value 
                } 'Integer' {
                    return [int]$Value 
                } default {
                    if ($Value -match '^(?i:true|false)$') {
                        return [bool]$Value 
                    } elseif ($Value -match '^[-]?\d+$') {
                        return [int]$Value 
                    }; return $Value 
                } 
            } 
        }
        function Convert-DirectorySetting {
            param([object]$Setting) $template = $templates | Where-Object { $_.id -eq $Setting.templateId }; $export = [ordered]@{ displayName = $Setting.displayName; present = $true }; foreach ($tVal in $template.values) {
                $current = $Setting.values | Where-Object { $_.name -eq $tVal.name }; if ($current) {
                    $export[$tVal.name] = Convert-Value -Value $current.value -Type $tVal.type 
                } 
            }; return $export 
        }
        function Get-AllSettings {
            $list = @(); $resp = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/settings?`$top=999"; if ($resp.keys -contains '@odata.nextLink') {
                do {
                    $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } while ($resp.'@odata.nextLink') 
            } else {
                $list += $resp.value 
            }; return $list 
        }
    }
    process {
        if ($SpecificResources) {
            $identifiers = @(); foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $identifiers = $identifiers | Select-Object -Unique; $allSettings = Get-AllSettings; foreach ($idOrName in $identifiers) {
                $match = $allSettings | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }; if ($match) {
                    foreach ($m in $match) {
                        $detail = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/settings/$($m.id)"; if ($detail) {
                            $directorySettingsExport += Convert-DirectorySetting $detail 
                        } 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfDirectorySetting' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                } 
            } 
        } else {
            $all = Get-AllSettings; foreach ($s in $all) {
                $directorySettingsExport += Convert-DirectorySetting $s 
            } 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfDirectorySetting' -Message "Exporting $($directorySettingsExport.Count) directory setting(s)"
        if ($OutPath) {
            if ($directorySettingsExport) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $directorySettingsExport -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $directorySettingsExport
                }
            }
        } else {
            return $directorySettingsExport
        }
    }
}
