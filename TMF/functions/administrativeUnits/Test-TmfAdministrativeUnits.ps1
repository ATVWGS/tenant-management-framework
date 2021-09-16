function Test-TmfAdministrativeUnits
{
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$componentName = "administrativeUnits"
		$tenant = Get-MgOrganization -Property displayName, Id		
	}
	process
	{
		foreach ($definition in $script:desiredConfiguration[$componentName]) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'administrativeUnits'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}
			$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/?`$filter=displayName eq '{0}'" -f $definition.displayName)).Value;

			switch ($resource.Count) {
				0 {
					if ($definition.present) {					
						$result = New-TestResult @result -ActionType "Create"
					}
					else {					
						$result = New-TestResult @result -ActionType "NoActionRequired"
					}
				}
				1 {
					$result["GraphResource"] = $resource
					if ($definition.present) {
						$changes = @()
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "present", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property
								Actions = $null
							}
							switch ($property) {
								"members" {
									$resourceMembers = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/members/$/microsoft.graph.user" -f $resource.Id)).Value.Id;
									$change.Actions = Compare-ResourceList -ReferenceList $resourceMembers `
														-DifferenceList $($definition.members | ForEach-Object {Resolve-User -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"groups" {
									$resourceGroups = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/members/$/microsoft.graph.group" -f $resource.Id)).Value.Id;
									$change.Actions = Compare-ResourceList -ReferenceList $resourceGroups `
														-DifferenceList $($definition.groups | ForEach-Object {Resolve-Group -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"scopedRoleMembers" {
									#$resourceScopedMembers 		= (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers" -f $resource.Id)).Value.roleMemberInfo.Id
									#$resourceScopedMembersRole 	= (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers" -f $resource.Id)).Value.roleId
									#$change.Actions = Compare-ResourceList -ReferenceList $resourceScopedMembers `
									#					-DifferenceList $($definition.scopedRoleMembers | ForEach-Object {Resolve-scopedRoleMember -InputReference $_ -Cmdlet $Cmdlet}) `
									#					-Cmdlet $PSCmdlet
								}
								default {
									if ($definition.$property -ne $resource.$property) {
										if(!( ($property -eq "visibility") -and !($resource.$property) -and ($definition.$property -eq "Public") )){
											$change.Actions = @{"Set" = $definition.$property};
										}
									}
								}
							}
							if ($change.Actions) {$changes += $change}
						}
	
						if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
						else { $result = New-TestResult @result -ActionType "NoActionRequired" }
					}
					else {
						$result = New-TestResult @result -ActionType "Delete"
					}
				}
				default {
					Write-PSFMessage -Level Warning -String 'TMF.Test.MultipleResourcesError' -StringValues $componentName, $definition.displayName -Tag 'failed'
					$exception = New-Object System.Data.DataException("Query returned multiple results. Cannot decide which resource to test.")
					$errorID = 'MultipleResourcesError'
					$category = [System.Management.Automation.ErrorCategory]::NotSpecified
					$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
					$cmdlet.ThrowTerminatingError($recordObject)
				}
			}
			$result
		}
	}
}
