<#
.SYNOPSIS
Exports custom authentication extensions.
.DESCRIPTION
Retrieves customAuthenticationExtensions. Returns objects unless -OutPath supplied. (Legacy alias: -OutPutPath)
.PARAMETER SpecificResources
Optional list of IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Force beta endpoint usage.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCustomAuthenticationExtension -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfCustomAuthenticationExtension -SpecificResources 'name1','name2'
#>
function Export-TmfCustomAuthenticationExtension {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'customAuthenticationExtensions'
        try {
            $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id") -ErrorAction Stop).value 
        } catch {
            $tenant = @(@{ displayName = 'Unknown'; id = '' }) 
        }
        $caeExport = @()
        function Convert-CAE {
            param([object]$CAE) 
            $e = [ordered]@{ 
                present = $true 
                "@odata.type" = $CAE."@odata.type"
                displayName = $CAE.displayName
                description = $CAE.description
                authenticationConfiguration = $CAE.authenticationConfiguration
                endpointConfiguration = $CAE.endpointConfiguration
                clientConfiguration = $CAE.clientConfiguration
            } 
            if ($CAE."@odata.type" -eq "#microsoft.graph.onTokenIssuanceStartCustomExtension") {
                $e.claimsForTokenConfiguration = $CAE.claimsForTokenConfiguration
            }
            return $e 
        }
        function Get-Paged {
            param([string]$Base) $all = @(); $uri = "$Base/identity/customAuthenticationExtensions"; while ($uri) {
                $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop; if ($resp.value) {
                    $all += $resp.value 
                }; $uri = $resp.'@odata.nextLink' 
            }; return $all 
        }
        function Get-AllExtensions {
            $list = @()
            if (-not $ForceBeta) {
                try {
                    $list = Get-Paged -Base $script:graphBaseUrl1 
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) 
                }
            }
            else {
                try {
                    $list = Get-Paged -Base $script:graphBaseUrlbeta
                } catch {
                    Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) 
                }
            }
            return $list
        }
    }
    process {
        if ($SpecificResources) {
            $ids = @(); foreach ($entry in $SpecificResources) {
                $ids += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $ids = $ids | Select-Object -Unique; $allExtensions = Get-AllExtensions; foreach ($idOrName in $ids) {
                $match = $allExtensions | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }; if ($match) {
                    foreach ($m in $match) {
                        $caeExport += Convert-CAE $m 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCustomAuthenticationExtension' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                } 
            } 
        } else {
            foreach ($cae in (Get-AllExtensions)) {
                $caeExport += Convert-CAE $cae
            } 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCustomAuthenticationExtension' -Message "Exporting $($caeExport.Count) custom authentication extension(s)"
        if (-not $OutPath) {
            return $caeExport 
        }
        $targetDir = Join-Path -Path $OutPath -ChildPath $resourceName
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
        }
        if ($caeExport) {
            if ($Append) {
                Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $caeExport -Append
            }
            else {
                Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $caeExport
            }
        }
    }
}
