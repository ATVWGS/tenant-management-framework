function Export-TmfDirectoryRole {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'directoryRoles'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        $roleExports = @()
        function Convert-Role {
            param([object]$role)
            $members = @()
            $memberResp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directoryRoles/$($role.id)/members?`$select=id,displayName,userPrincipalName"
            if ($memberResp) {
                if ($memberResp.keys -contains '@odata.nextLink') {
                    do {
                        $members += $memberResp.value
                        $memberResp = Invoke-MgGraphRequest -Method GET -Uri $memberResp.'@odata.nextLink'
                    } while ($memberResp.'@odata.nextLink')
                } else { $members += $memberResp.value }
            }
            $memberObjects = @()
            foreach ($m in $members) {
                switch ($m.'@odata.type') {
                    '#microsoft.graph.user' {
                        $memberObjects += [ordered]@{type='singleUser';reference=$m.userPrincipalName}
                    }
                    '#microsoft.graph.group' {
                        $memberObjects += [ordered]@{type='group';reference=$m.displayName}
                    }
                }
            }
            $obj = [ordered]@{
                displayName = $role.displayName
                present     = $true
            }
            if ($memberObjects) { $obj.members = $memberObjects }
            return $obj
        }
        function Get-AllRoles {
            $list = @()
            $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directoryRoles?`$select=id,displayName"
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
            $allRoles = Get-AllRoles
            foreach ($idOrName in $identifiers) {
                $match = $allRoles | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) { foreach ($m in $match) { $roleExports += Convert-Role $m } }
                else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfDirectoryRole' -String 'TMF.Export.NotFound' -StringValues $idOrName,$resourceName,$tenant.displayName }
            }
        } else {
            $all = Get-AllRoles
            foreach ($r in $all) { $roleExports += Convert-Role $r }
        }
    }
    end {
        if (-not (Test-Path "$OutPutPath/$($resourceName)")) { New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force | Out-Null }
        $roleExports | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutPutPath/$resourceName/$resourceName.json" -Encoding utf8 -Force
    }
}