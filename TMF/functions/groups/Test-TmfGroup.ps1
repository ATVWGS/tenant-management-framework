function Test-TmfGroup
{
	[CmdletBinding()]
	Param (	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id		
	}
	process
	{
		$results = @()
		foreach ($definition in $script:desiredConfiguration["groups"]) {

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'Group'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			$resource = Get-MgGroup -Filter "displayName eq '$($definition.displayName)'"

			if ($resource) {
				$result["GraphResource"] = $resource
				if ($definition.present) {
					$changes = @()
					foreach ($property in ($definition.Properties() | ? {$_ -notin "displayName", "present", "sourceConfig"})) {
						$change = [PSCustomObject] @{
							Property = $property										
							Actions = $null
						}
						switch ($property) {
							"members" {
								$change.Actions = (Compare-UserList -Target $definition.displayName -ReferenceList (Get-MgGroupMember -GroupId $resource.Id).Id -DifferenceList $definition.members -Cmdlet $PSCmdlet)
							}
							"owners" {
								$change.Actions = (Compare-UserList -Target $definition.displayName -ReferenceList (Get-MgGroupOwner -GroupId $resource.Id).Id -DifferenceList $definition.owners -Cmdlet $PSCmdlet)
							}
							"membershipRule" {
								if ($definition.$property -ne $resource.$property) {
									$change.Actions = @{"Set" = $definition.$property}
								}
								$changes += [PSCustomObject] @{
									Property = "membershipRuleProcessingState"										
									Actions = @{"Set" = "On"}
								}
							}
							"groupTypes" {
								if (Compare-Object -ReferenceObject $resource.groupTypes -DifferenceObject $definition.groupTypes) {
									$change.Actions = @{"Set" = $definition.groupTypes}
								}
							}
							default {
								if ($definition.$property -ne $resource.$property) {
									$change.Actions = @{"Set" = $definition.$property}
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
			else {
				if ($definition.present) {					
					$result = New-TestResult @result -ActionType "Create"
				}
				else {					
					$result = New-TestResult @result -ActionType "NoActionRequired"
				}
			}
			
			$result
		}
	}
}
