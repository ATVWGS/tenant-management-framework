function Test-TmfGroup
{
	<#
		.SYNOPSIS
			Test desired configuration against a Tenant.
		.DESCRIPTION
			Compare current configuration of a resource type with the desired configuration.
			Return a result object with the required changes and actions.
	#>
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$componentName = "groups"
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
				ResourceType = 'Group'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			if ("oldNames" -in $definition.Properties()) {				
				$filter = ($definition.oldNames + $definition.displayName | Foreach-Object {
					"(displayName eq '{0}')" -f [System.Web.HttpUtility]::UrlEncode($_)
				}) -join " or "
			}
			else {
				$filter = "(displayName eq '{0}')" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName)
			}
			try {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter={0}" -f $filter)).Value
			}
			catch {
				Write-PSFMessage -Level Warning -String 'TMF.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
				$exception = New-Object System.Data.DataException("Query with filter $filter against Microsoft Graph failed. Error: $_")
				$errorID = 'QueryWithFilterFailed'
				$category = [System.Management.Automation.ErrorCategory]::NotSpecified
				$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
				$cmdlet.ThrowTerminatingError($recordObject)
			}

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
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "oldNames", "present", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property
								Actions = $null
							}
							switch ($property) {
								"members" {
									$resourceMembers = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}/members" -f $resource.Id)).Value.Id
									$change.Actions = Compare-ResourceList -ReferenceList $resourceMembers `
														-DifferenceList $($definition.members | ForEach-Object {Resolve-User -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"owners" {									
									$resourceOwners = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}/owners" -f $resource.Id)).Value.Id
									$change.Actions = Compare-ResourceList -ReferenceList $resourceOwners `
														-DifferenceList $($definition.owners | ForEach-Object {Resolve-User -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"membershipRule" {
									if ($definition.$property -ne $resource.$property) {
										$change.Actions = @{"Set" = $definition.$property}
										$changes += [PSCustomObject] @{
											Property = "membershipRuleProcessingState"										
											Actions = @{"Set" = "On"}
										}
									}								
								}
								"groupTypes" {
									if ($resource.groupTypes) {
										if (Compare-Object -ReferenceObject $resource.groupTypes -DifferenceObject $definition.groupTypes) {
											$change.Actions = @{"Set" = $definition.groupTypes}
										}
									}
									else {
										if ($definition.groupTypes.count -gt 0) {
											$change.Actions = @{"Set" = $definition.groupTypes}
										}
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
