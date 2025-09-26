<#
.SYNOPSIS
Exports authentication context class references.
.DESCRIPTION
Retrieves authenticationContextClassReferences (v1.0 with beta fallback) merging missing properties. Returns objects unless -OutPath supplied. (Legacy alias: -OutPutPath)
.PARAMETER SpecificResources
Optional list of IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER ForceBeta
Force beta endpoint usage.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAuthenticationContextClassReference -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfAuthenticationContextClassReference -SpecificResources 'c1','HighRisk'
#>
function Export-TmfAuthenticationContextClassReference {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'authenticationContextClassReferences'
        try {
            $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id") -ErrorAction Stop).value 
        } catch {
            $tenant = @(@{ displayName = 'Unknown'; id = '' }) 
        }
        $accrExport = @()
        function Convert-Value {
            param([string]$Value) if ($null -eq $Value) {
                return $null 
            }; if ($Value -match '^(?i:true|false)$') {
                return [bool]$Value 
            }; if ($Value -match '^[-]?\d+$') {
                return [int]$Value 
            }; return $Value 
        }
        function Convert-ACCR {
            param([object]$Ref) $e = [ordered]@{ displayName = $Ref.displayName; id = $Ref.id; isAvailable = (Convert-Value $Ref.isAvailable); present = $true }; if ($Ref.PSObject.Properties['description']) {
                $e.description = $Ref.description 
            }; return $e 
        }
        function Get-Paged {
            param([string]$Base) $all = @(); $uri = "$Base/identity/conditionalAccess/authenticationContextClassReferences?"; while ($uri) {
                $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop; if ($resp.value) {
                    $all += $resp.value 
                }; $uri = $resp.'@odata.nextLink' 
            }; return $all 
        }
        function Get-AllReferences {
            $list = @(); $usedBeta = $false
            if (-not $ForceBeta) {
                try {
                    $list = Get-Paged -Base $script:graphBaseUrl1 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) 
                }
            }
            $needBeta = $ForceBeta.IsPresent -or ($list.Count -eq 0) -or ($list | Where-Object { -not ($_.PSObject.Properties.Name -contains 'isAvailable') })
            if ($needBeta) {
                try {
                    $betaList = Get-Paged -Base $script:graphBaseUrlbeta
                    if ($betaList.Count -gt 0) {
                        if ($list.Count -eq 0) {
                            $list = $betaList 
                        } else {
                            foreach ($b in $betaList) {
                                $existing = $list | Where-Object { $_.id -eq $b.id }
                                if ($existing) {
                                    if (-not ($existing.PSObject.Properties.Name -contains 'isAvailable') -and ($b.PSObject.Properties.Name -contains 'isAvailable')) {
                                        $existing | Add-Member -NotePropertyName isAvailable -NotePropertyValue $b.isAvailable -Force 
                                    }
                                    if (-not ($existing.PSObject.Properties.Name -contains 'description') -and ($b.PSObject.Properties.Name -contains 'description')) {
                                        $existing | Add-Member -NotePropertyName description -NotePropertyValue $b.description -Force 
                                    }
                                } else {
                                    $list += $b 
                                }
                            }
                        }
                    }
                    $usedBeta = $true
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message) 
                }
            }
            if ($usedBeta) {
                Write-PSFMessage -Level Verbose -Message 'Returned data includes beta fallback.' 
            } else {
                Write-PSFMessage -Level Verbose -Message 'Returned data from v1.0 only.' 
            }
            return $list
        }
    }
    process {
        if ($SpecificResources) {
            $ids = @(); foreach ($entry in $SpecificResources) {
                $ids += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $ids = $ids | Select-Object -Unique; $allRefs = Get-AllReferences; foreach ($idOrName in $ids) {
                $match = $allRefs | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }; if ($match) {
                    foreach ($m in $match) {
                        $accrExport += Convert-ACCR $m 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAuthenticationContextClassReference' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                } 
            } 
        } else {
            foreach ($r in (Get-AllReferences)) {
                $accrExport += Convert-ACCR $r 
            } 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationContextClassReference' -Message "Exporting $($accrExport.Count) authentication context class reference(s)"
        if (-not $OutPath) {
            return $accrExport 
        }
        $targetDir = Join-Path -Path $OutPath -ChildPath $resourceName
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
        }
        $accrExport | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir "$resourceName.json") -Encoding utf8 -Force
    }
}
