function Export-TmfGroup {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'groups'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        $groupsExport = @()
        $select = 'id,displayName,description,groupTypes,securityEnabled,mailEnabled,visibility,mailNickname'
        function Convert-Group {
            param([object]$g)
            $obj = [ordered]@{
                displayName     = $g.displayName
                description     = $g.description
                groupTypes      = $g.groupTypes
                securityEnabled = $g.securityEnabled
                mailEnabled     = $g.mailEnabled
                visibility      = $g.visibility
                mailNickname    = $g.mailNickname
                present         = $true
            }
            return $obj
        }
        function Get-AllGroups {
            $list = @()
            $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/groups?`$top=999&`$select=$select"
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
            foreach ($entry in $SpecificResources) { $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
            $identifiers = $identifiers | Select-Object -Unique
            $allGroups = Get-AllGroups
            foreach ($idOrName in $identifiers) {
                $match = $allGroups | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) { foreach ($m in $match) { $groupsExport += Convert-Group $m } }
                else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfGroup' -String 'TMF.Export.NotFound' -StringValues $idOrName,$resourceName,$tenant.displayName }
            }
        } else {
            $all = Get-AllGroups
            foreach ($g in $all) { $groupsExport += Convert-Group $g }
        }
    }
    end {
        if (-not (Test-Path "$OutPutPath/$($resourceName)")) { New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force | Out-Null }
        $groupsExport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutPutPath/$resourceName/$resourceName.json" -Encoding utf8 -Force
    }
}