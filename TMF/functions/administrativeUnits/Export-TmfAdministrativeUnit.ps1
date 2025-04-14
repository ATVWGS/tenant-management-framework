function Export-TmfAdministrativeUnit
{
	[CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
        [string] $OutPutPath,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "administrativeUnits"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        $administrativeUnitsExport = @()
	}
	process
	{
        if ($SpecificResources) {
            foreach ($resource in $SpecificResources) {
                $AU = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/administrativeUnits?`$filter=displayname eq '$($resource)'").value
                if ($AU) {
                    $AUmembers = @()
                    $AUusers = @()
                    $AUgroups = @()
                    $AUdevices = @()
                    if ($AU.membershipType -ne "Dynamic") {

                        $mResponse = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/administrativeUnits/$($AU.id)/members")

                        if ($mResponse.keys -contains "@odata.nextLink") {
                            $AUmembers += $mResponse.value
                            while ($null -ne $mResponse."@odata.nextLink") {
                                $mResponse = Invoke-MgGraphRequest -Method GET -Uri $mResponse.'@odata.nextLink'
                                $AUmembers += $mResponse.value
                            }
                        }
                        else {
                            $AUmembers += $mResponse.value
                        }
                        $AUusers += ($AUmembers | Where-Object {$_."@odata.type" -eq "#microsoft.graph.user"}).id
                        $AUgroups += ($AUmembers | Where-Object {$_."@odata.type" -eq "#microsoft.graph.group"}).id
                        $AUdevices += ($AUmembers | Where-Object {$_."@odata.type" -eq "#microsoft.graph.device"}).id
                    }

                    $AUscopedRoleMembers = @()
                    $srmResponse = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/administrativeUnits/$($AU.id)/scopedRoleMembers")
                    if ($srmResponse.value) {
                        foreach ($scopedRoleMember in $srmResponse.value) {
                            $AUscopedRoleMembers += @{
                                "role" = $scopedRoleMember.roleId
                                "identity" = $scopedRoleMember.roleMemberInfo.displayName
                            }
                        }
                    }

                    if ($AU.membershipType -eq "Dynamic") {
                        $administrativeUnitsExport += [ordered]@{
                            "displayName" = $AU.displayName
                            "description" = $AU.description
                            "visibility" = $AU.visibility
                            "membershipType" = $AU.membershipType
                            "membershipRule" = $AU.membershipRule
                            "membershipRuleProcessingState" = $AU.membershipRuleProcessingState
                            "scopedRoleMembers" = $AUscopedRoleMembers
                            "present" = $true
                        }
                    }
                    elseif ((-not ($AUusers)) -and (-not ($AUgroups)) -and (-not ($AUdevices))) {
                        $administrativeUnitsExport += [ordered]@{
                            "displayName" = $AU.displayName
                            "description" = $AU.description
                            "visibility" = $AU.visibility
                            "membershipType" = $AU.membershipType
                            "scopedRoleMembers" = $AUscopedRoleMembers
                            "present" = $true
                        }
                    }
                    else {
                        if (-not ($AUusers)) {$AUusers = @()}
                        if (-not ($AUgroups)) {$AUgroups = @()}
                        if (-not ($AUdevices)) {$AUdevices = @()}
                        $administrativeUnitsExport += [ordered]@{
                            "displayName" = $AU.displayName
                            "description" = $AU.description
                            "visibility" = $AU.visibility
                            "membershipType" = $AU.membershipType
                            "users" = $AUusers
                            "groups" = $AUgroups
                            "devices" = $AUdevices
                            "scopedRoleMembers" = $AUscopedRoleMembers
                            "present" = $true
                        }
                    }
                }
                else {
                    Write-PSFMessage -Level Warning -FunctionName "Export-TmfAdministrativeUnit" -String "TMF.Export.NotFound" -StringValues $resource,$resourceName,$tenant.displayName
                }
            }
        }
        else {
            $AUs = @()
            $AUresponse = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/administrativeUnits?`$top=999"

            if ($AUresponse.keys -contains "@odata.nextLink") {
                do {
                    $AUs += $AUresponse.value
                    $AUresponse = Invoke-MgGraphRequest -Method GET -Uri $AUresponse.'@odata.nextLink'
                }
                while ($AUresponse."@odata.nextLink")
            }
            else {
                $AUs += $AUresponse.value
            }
            
            foreach ($AU in $AUs) {
                $AUmembers = @()
                $AUusers = @()
                $AUgroups = @()
                $AUdevices = @()
                if ($AU.membershipType -ne "Dynamic") {

                    $mResponse = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/administrativeUnits/$($AU.id)/members")

                    if ($mResponse.keys -contains "@odata.nextLink") {
                        $AUmembers += $mResponse.value
                        while ($null -ne $mResponse."@odata.nextLink") {
                            $mResponse = Invoke-MgGraphRequest -Method GET -Uri $mResponse.'@odata.nextLink'
                            $AUmembers += $mResponse.value
                        }
                    }
                    else {
                        $AUmembers += $mResponse.value
                    }
                    $AUusers += ($AUmembers | Where-Object {$_."@odata.type" -eq "#microsoft.graph.user"}).id
                    $AUgroups += ($AUmembers | Where-Object {$_."@odata.type" -eq "#microsoft.graph.group"}).id
                    $AUdevices += ($AUmembers | Where-Object {$_."@odata.type" -eq "#microsoft.graph.device"}).id
                }

                $AUscopedRoleMembers = @()
                $srmResponse = (Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/directory/administrativeUnits/$($AU.id)/scopedRoleMembers")
                if ($srmResponse.value) {
                    foreach ($scopedRoleMember in $srmResponse.value) {
                        $AUscopedRoleMembers += @{
                            "role" = $scopedRoleMember.roleId
                            "identity" = $scopedRoleMember.roleMemberInfo.displayName
                        }
                    }
                }

                if ($AU.membershipType -eq "Dynamic") {
                    $administrativeUnitsExport += [ordered]@{
                        "displayName" = $AU.displayName
                        "description" = $AU.description
                        "visibility" = $AU.visibility
                        "membershipType" = $AU.membershipType
                        "membershipRule" = $AU.membershipRule
                        "membershipRuleProcessingState" = $AU.membershipRuleProcessingState
                        "scopedRoleMembers" = $AUscopedRoleMembers
                        "present" = $true
                    }
                }
                elseif ((-not ($AUusers)) -and (-not ($AUgroups)) -and (-not ($AUdevices))) {
                    $administrativeUnitsExport += [ordered]@{
                        "displayName" = $AU.displayName
                        "description" = $AU.description
                        "visibility" = $AU.visibility
                        "membershipType" = $AU.membershipType
                        "scopedRoleMembers" = $AUscopedRoleMembers
                        "present" = $true
                    }
                }
                else {
                    if (-not ($AUusers)) {$AUusers = @()}
                    if (-not ($AUgroups)) {$AUgroups = @()}
                    if (-not ($AUdevices)) {$AUdevices = @()}
                    $administrativeUnitsExport += [ordered]@{
                        "displayName" = $AU.displayName
                        "description" = $AU.description
                        "visibility" = $AU.visibility
                        "membershipType" = $AU.membershipType
                        "users" = $AUusers
                        "groups" = $AUgroups
                        "devices" = $AUdevices
                        "scopedRoleMembers" = $AUscopedRoleMembers
                        "present" = $true
                    }
                }                 
            }
        }
    }
    end {
        if (-not (Test-Path "$OutPutPath/$($resourceName)")) {
            New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force
        }
        $administrativeUnitsExport | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutPutPath/$($resourceName)/$($resourceName).json" -Encoding utf8 -Force
    }
}