<#
.SYNOPSIS
Exports administrative units and their members/scoped role members.
.DESCRIPTION
Retrieves administrative units (optionally filtered) including users, groups, devices, dynamic rules, and scoped role members. Returns objects unless -OutPutPath supplied.
.PARAMETER SpecificResources
Optional list of AU display names to export (comma separated accepted).
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER IncludeMembers
Include members of administrative unit in export.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAdministrativeUnit -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfAdministrativeUnit -SpecificResources 'Marketing','HR'
#>
function Export-TmfAdministrativeUnit {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [switch] $IncludeMembers,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'administrativeUnits'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        if ($ForceBeta) {
            $graphUrl = $script:graphBaseUrl
        }
        else {
            $graphUrl = $script:graphBaseUrl1
        }
        $administrativeUnitsExport = @()
    }
    process {
        function Get-AUMembers {
            param([string]$Id, [string]$MembershipType)
            $users = @(); $groups = @(); $devices = @()
            if ($MembershipType -ne 'Dynamic') {
                $mResponse = Invoke-MgGraphRequest -Method GET -Uri ("$($graphUrl)/directory/administrativeUnits/$Id/members")
                while ($mResponse) {
                    if ($mResponse.value) {
                        $users += ($mResponse.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.user' }).id; $groups += ($mResponse.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.group' }).id; $devices += ($mResponse.value | Where-Object { $_.'@odata.type' -eq '#microsoft.graph.device' }).id 
                    }
                    if ($mResponse.'@odata.nextLink') {
                        $mResponse = Invoke-MgGraphRequest -Method GET -Uri $mResponse.'@odata.nextLink' 
                    } else {
                        $mResponse = $null 
                    }
                }
            }
            return [pscustomobject]@{ users = $users; groups = $groups; devices = $devices }
        }
        function Get-AUScopedRoleMembers {
            param([string]$Id) $result = @(); $srm = Invoke-MgGraphRequest -Method GET -Uri ("$($graphUrl)/directory/administrativeUnits/$Id/scopedRoleMembers"); while ($srm) {
                if ($srm.value) {
                    foreach ($s in $srm.value) {
                        $result += @{ identity = $s.roleMemberInfo.displayName; role = (Resolve-DirectoryRole -InputReference $s.roleId -DisplayName -DontFailIfNotExisting -Cmdlet $Cmdlet); roleId = $s.roleId } 
                    } 
                }; if ($srm.'@odata.nextLink') {
                    $srm = Invoke-MgGraphRequest -Method GET -Uri $srm.'@odata.nextLink' 
                } else {
                    $srm = $null 
                } 
            }; return $result 
        }
        if ($SpecificResources) {
            foreach ($name in ($SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ })) {
                $escaped = $name -replace "'", "''"
                $AU = (Invoke-MgGraphRequest -Method GET -Uri ("$($graphUrl)/directory/administrativeUnits?`$filter=displayName eq '{0}'" -f $escaped)).value
                if ($AU) {
                    if ($IncludeMembers) {
                        $members = Get-AUMembers -Id $AU.id -MembershipType $AU.membershipType
                    }                    
                    $scoped = Get-AUScopedRoleMembers -Id $AU.id
                    $base = [ordered]@{ displayName = $AU.displayName; description = $AU.description; present = $true }
                    if ($AU.membershipType -eq 'Dynamic') {
                        $base.membershipRule = $AU.membershipRule; $base.membershipRuleProcessingState = $AU.membershipRuleProcessingState 
                    } elseif ($members.users -or $members.groups -or $members.devices) {
                        if ($members.users) {
                            $base.users = $members.users
                        }
                        if ($members.groups) {
                            $base.groups = $members.groups
                        }
                        if ($members.devices) {
                            $base.devices = $members.devices 
                        }
                    }
                    if ($AU.membershipType) {
                        $base.membershipType = $AU.membershipType
                    }
                    if ($scoped) {
                        $base.scopedRoleMembers = $scoped
                    }
                    if ($AU.visibility) {
                        $base.visibility = $AU.visibility
                    }
                    $administrativeUnitsExport += $base
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAdministrativeUnit' -String 'TMF.Export.NotFound' -StringValues $name, $resourceName, $tenant.displayName 
                }
            }
        } else {
            $all = @(); $resp = Invoke-MgGraphRequest -Method GET -Uri "$($graphUrl)/directory/administrativeUnits?`$top=999"; while ($resp) {
                if ($resp.value) {
                    $all += $resp.value 
                }; if ($resp.'@odata.nextLink') {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } else {
                    $resp = $null 
                } 
            }
            foreach ($AU in $all) {
                if ($AU.membershipType -ne 'Dynamic' -and $IncludeMembers) {
                    $members = Get-AUMembers -Id $AU.id -MembershipType $AU.membershipType
                }                
                $scoped = Get-AUScopedRoleMembers -Id $AU.id
                $base = [ordered]@{ displayName = $AU.displayName; description = $AU.description; present = $true }
                if ($AU.membershipType -eq 'Dynamic') {
                    $base.membershipRule = $AU.membershipRule; $base.membershipRuleProcessingState = $AU.membershipRuleProcessingState 
                } elseif ($members.users -or $members.groups -or $members.devices) {
                    if ($members.users) {
                        $base.users = $members.users
                    }
                    if ($members.groups) {
                        $base.groups = $members.groups
                    }
                    if ($members.devices) {
                        $base.devices = $members.devices 
                    }
                }
                if ($AU.membershipType) {
                    $base.membershipType = $AU.membershipType
                }
                if ($scoped) {
                    $base.scopedRoleMembers = $scoped
                }
                if ($AU.visibility) {
                    $base.visibility = $AU.visibility
                }
                $administrativeUnitsExport += $base
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAdministrativeUnit' -Message "Exporting $($administrativeUnitsExport.Count) administrative unit(s)"
        if (-not $OutPath) {
            return $administrativeUnitsExport 
        }
        Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $administrativeUnitsExport
    }
}
