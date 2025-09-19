<#
.SYNOPSIS
Exports directory roles and (user/group) members.
.DESCRIPTION
Retrieves directory roles and enumerates user and group members. Returns objects unless -OutPutPath supplied.
.PARAMETER SpecificResources
Optional list of role display names or IDs (comma separated accepted).
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfDirectoryRole -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfDirectoryRole -SpecificResources 'Global Reader','Security Administrator'
#>
function Export-TmfDirectoryRole {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        Write-TmfDeprecatedParameterWarning -Parameters $PSBoundParameters -LegacyName 'OutPutPath' -NewName 'OutPath'
        # TODO: Add Pester tests for -OutPath deprecation (CI-002)
        $resourceName = 'directoryRoles'
        $graphBase = if ($ForceBeta) {
            $script:graphBaseUrl 
        } else {
            $script:graphBaseUrl1 
        }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $roleExports = @()
        function Convert-Role {
            param([object]$role) $members = @(); $resp = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/directoryRoles/$($role.id)/members?`$select=id,displayName,userPrincipalName"; while ($resp) {
                if ($resp.value) {
                    $members += $resp.value 
                }; if ($resp.'@odata.nextLink') {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } else {
                    $resp = $null 
                } 
            }; $memberObjects = @(); foreach ($m in $members) {
                switch ($m.'@odata.type') {
                    '#microsoft.graph.user' {
                        $memberObjects += [ordered]@{ type = 'singleUser'; reference = $m.userPrincipalName } 
                    } '#microsoft.graph.group' {
                        $memberObjects += [ordered]@{ type = 'group'; reference = $m.displayName } 
                    } 
                } 
            }; $obj = [ordered]@{ displayName = $role.displayName; present = $true }; if ($memberObjects) {
                $obj.members = $memberObjects 
            }; return $obj 
        }
        function Get-AllRoles {
            $list = @(); $resp = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/directoryRoles?`$select=id,displayName"; while ($resp) {
                if ($resp.value) {
                    $list += $resp.value 
                }; if ($resp.'@odata.nextLink') {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } else {
                    $resp = $null 
                } 
            }; return $list 
        }
    }
    process {
        if ($SpecificResources) {
            $ids = @(); foreach ($e in $SpecificResources) {
                $ids += $e -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $ids = $ids | Select-Object -Unique; $all = Get-AllRoles; foreach ($idOrName in $ids) {
                $match = $all | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }; if ($match) {
                    foreach ($m in $match) {
                        $roleExports += Convert-Role $m 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfDirectoryRole' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                } 
            } 
        } else {
            foreach ($r in (Get-AllRoles)) {
                $roleExports += Convert-Role $r 
            } 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfDirectoryRole' -Message "Exporting $($roleExports.Count) directory role(s)"
        if (-not $OutPath) {
            return $roleExports 
        }
        $targetDir = Join-Path -Path $OutPath -ChildPath $resourceName
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -Path $OutPath -Name $resourceName -ItemType Directory -Force | Out-Null 
        }
        $roleExports | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir "$resourceName.json") -Encoding utf8 -Force
    }
}
