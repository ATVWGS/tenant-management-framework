<#
.SYNOPSIS
Exports custom security attribute definitions into TMF configuration.
.DESCRIPTION
Retrieves customSecurityAttributeDefinitions (v1.0) and outputs TMF objects. Returns objects unless -OutPath supplied. (Legacy alias: -OutPutPath)
.PARAMETER SpecificResources
Optional list of definition display names or internal names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCustomSecurityAttributeDefinition -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfCustomSecurityAttributeDefinition -SpecificResources CostCenter,Region
#>
function Export-TmfCustomSecurityAttributeDefinition {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'customSecurityAttributeDefinitions'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id")).value
        $export = @()
        function Convert-Definition {
            param([object]$d, [object[]]$vals) [ordered]@{ displayName = $d.id; description = $d.description; attributeSet = $d.attributeSet; name = $d.name; isCollection = $d.isCollection; isSearchable = $d.isSearchable; status = $d.status; type = $d.type; usePreDefinedValuesOnly = $d.usePreDefinedValuesOnly; allowedValues = $vals; present = $true }
        }
        function Get-AllDefinitions {
            $list = @(); $apiBase = if ($ForceBeta) {
                $script:graphBaseUrlbeta
            } else {
                $script:graphBaseUrl1
            }; try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/directory/customSecurityAttributeDefinitions?`$top=999" -ErrorAction Stop; if ($resp.'@odata.nextLink') {
                    do {
                        $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink'
                    } while ($resp.'@odata.nextLink')
                } else {
                    $list += $resp.value
                }
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeDefinition' -Message "Unable to retrieve customSecurityAttributeDefinitions: $($_.Exception.Message)"
            }; return $list
        }
        $all = Get-AllDefinitions
    }
    process {
        function Get-AllowedValuesForDefinition {
            param([object]$def)
            $vals = @()
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri ("$((if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 }))/directory/customSecurityAttributeDefinitions/{0}/allowedValues?`$top=999" -f [System.Web.HttpUtility]::UrlEncode($def.id)) -ErrorAction Stop
                if ($resp.'@odata.nextLink') {
                    do {
                        $vals += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink'
                    } while ($resp.'@odata.nextLink')
                } else {
                    $vals += $resp.value
                }
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeDefinition' -Message ("Failed to retrieve allowedValues for definition {0}: {1}" -f $def.id, $_.Exception.Message)
            }
            return ($vals | ForEach-Object { [ordered]@{ displayName = $_.id; isActive = $_.isActive } })
        }

        $targets = if ($SpecificResources) {
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique
            $selected = @()
            foreach ($id in $ids) {
                $match = $all | Where-Object { $_.displayName -eq $id -or $_.name -eq $id }
                if ($match) {
                    $selected += $match
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomSecurityAttributeDefinition' -String 'TMF.Export.NotFound' -StringValues $id, $resourceName, $tenant.displayName
                }
            }
            $selected
        } else {
            $all
        }

        foreach ($d in $targets) {
            $vals = Get-AllowedValuesForDefinition -def $d
            $export += Convert-Definition $d $vals
        }
    }
    end {
        if (-not $OutPath) {
            return $export
        }; $root = Join-Path $OutPath 'customSecurityAttributes'; if (-not (Test-Path $root)) {
            New-Item -Path $OutPath -Name 'customSecurityAttributes' -ItemType Directory -Force | Out-Null
        }; $path = Join-Path $root $resourceName; if (-not (Test-Path $path)) {
            New-Item -Path $root -Name $resourceName -ItemType Directory -Force | Out-Null
        }; $export | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $path "$resourceName.json") -Encoding utf8 -Force
    }
}
