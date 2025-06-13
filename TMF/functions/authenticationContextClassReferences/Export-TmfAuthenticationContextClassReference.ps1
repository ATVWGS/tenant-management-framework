function Export-TmfAuthenticationContextClassReference {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'authenticationContextClassReferences'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        $accrExport = @()

        function Convert-Value {
            param([string] $Value)
            if ($null -eq $Value) { return $null }
            if ($Value -match '^(?i:true|false)$') { return [System.Convert]::ToBoolean($Value) }
            if ($Value -match '^[-]?\d+$') { return [int] $Value }
            return $Value
        }

        function Convert-ACCR {
            param([object]$Ref)
            $export = [ordered]@{
                displayName = $Ref.displayName
                id          = $Ref.id
            }
            if ($Ref.PSObject.Properties['description']) { $export.description = $Ref.description }
            $export.isAvailable = Convert-Value $Ref.isAvailable
            $export.present     = $true
            return $export
        }

        function Get-AllReferences {
            $list = @()
            $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/identity/conditionalAccess/authenticationContextClassReferences?`$top=999"
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
    }
    process {
        if ($SpecificResources) {
            $identifiers = @()
            foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $identifiers = $identifiers | Select-Object -Unique
            $allRefs = Get-AllReferences

            foreach ($idOrName in $identifiers) {
                $match = $allRefs | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) { $accrExport += Convert-ACCR $m }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAuthenticationContextClassReference' -String 'TMF.Export.NotFound' -StringValues $idOrName,$resourceName,$tenant.displayName
                }
            }
        } else {
            $all = Get-AllReferences
            foreach ($r in $all) { $accrExport += Convert-ACCR $r }
        }
    }
    end {
        if (-not (Test-Path "$OutPutPath/$($resourceName)")) {
            New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force | Out-Null
        }
        $accrExport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutPutPath/$($resourceName)/$($resourceName).json" -Encoding utf8 -Force
    }
}