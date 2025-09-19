<#
.SYNOPSIS
Exports named locations into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves named locations (v1.0 by default; beta when -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied. Legacy alias -OutPutPath is deprecated.
.PARAMETER SpecificResources
Optional list of named location IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write the export. When omitted, objects are returned instead of writing files. Legacy alias -OutPutPath accepted (deprecated).
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfNamedLocation -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfNamedLocation -SpecificResources "Location 1","abcd-1234" | ConvertTo-Json -Depth 15
#>
function Export-TmfNamedLocation {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'namedLocations'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $namedLocationsExport = @()
        function Convert-NamedLocation {
            param([object]$location) $obj = [ordered]@{ displayName = $location.displayName; id = $location.id; present = $true }; if ($location.'@odata.type' -eq '#microsoft.graph.ipNamedLocation') {
                $obj.type = 'ipNamedLocation'; $obj.isTrusted = $location.isTrusted; $obj.ipRanges = $location.ipRanges 
            } elseif ($location.'@odata.type' -eq '#microsoft.graph.countryNamedLocation') {
                $obj.type = 'countryNamedLocation'; $obj.countriesAndRegions = $location.countriesAndRegions; $obj.includeUnknownCountriesAndRegions = $location.includeUnknownCountriesAndRegions 
            } else {
                $obj.type = 'namedLocation' 
            }; return $obj 
        }
        function Get-AllNamedLocations {
            $list = @(); $resp = Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/identity/conditionalAccess/namedLocations"; if ($resp.keys -contains '@odata.nextLink') {
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
            $identifiers = @()
            foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }
            $identifiers = $identifiers | Select-Object -Unique
            $allNamedLocations = Get-AllNamedLocations
            foreach ($idOrName in $identifiers) {
                $match = $allNamedLocations | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) {
                        $namedLocationsExport += Convert-NamedLocation $m 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfNamedLocation' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                }
            }
        } else {
            $allNamedLocations = Get-AllNamedLocations
            foreach ($location in $allNamedLocations) {
                $namedLocationsExport += Convert-NamedLocation $location
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfNamedLocation' -Message "Exporting $($namedLocationsExport.Count) named location(s). ForceBeta=$ForceBeta"
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -InvocationLine $MyInvocation.Line -LegacyParameter 'OutPutPath' -NewParameter 'OutPath' 
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $namedLocationsExport
        } else {
            return $namedLocationsExport
        }
    }
}
