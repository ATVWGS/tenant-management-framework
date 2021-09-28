function Test-TmfConditionalAccessPolicy
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
		$resourceName = "conditionalAccessPolicies"
		$tenant = Get-MgOrganization -Property displayName, Id
		
		$resolveFunctionMapping = @{
			"Users" = (Get-Command Resolve-User)
			"Groups" = (Get-Command Resolve-Group)
			"Applications" = (Get-Command Resolve-Application)
			"Roles" = (Get-Command Resolve-DirectoryRole)
			"Locations" = (Get-Command Resolve-NamedLocation)
			"Platforms" = "DirectCompare"
		}
		$conditionPropertyRegex = [regex]"^(include|exclude)($($resolveFunctionMapping.Keys -join "|"))$"
	}
	process
	{
		foreach ($definition in $script:desiredConfiguration[$resourceName]) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'ConditionalAccessPolicy'
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
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/policies?`$filter={0}" -f $filter)).Value
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

							$conditionPropertyMatch = $conditionPropertyRegex.Match($property)
							$propertyTargetResourceType = $conditionPropertyMatch.Groups[2].Value

							if ($propertyTargetResourceType -in @("Users", "Groups", "Roles")) {
								$change.Actions = Compare-ResourceList -ReferenceList $resource.conditions.users.$property `
														-DifferenceList $($definition.$property | ForEach-Object {& $resolveFunctionMapping[$propertyTargetResourceType] -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet -ReturnSetAction
							}
							elseif ($propertyTargetResourceType -in $resolveFunctionMapping.Keys) {
								if ($resolveFunctionMapping[$propertyTargetResourceType] -eq "DirectCompare") {									
									if (Compare-Object -ReferenceObject $resource.conditions.$($propertyTargetResourceType.toLower()).$property -DifferenceObject $definition.$property) {
										$change.Actions = @{"Set" = $definition.$property}
									}
								}
								else {
									$change.Actions = Compare-ResourceList -ReferenceList $resource.conditions.$($propertyTargetResourceType.toLower()).$property `
														-DifferenceList $($definition.$property | ForEach-Object {& $resolveFunctionMapping[$propertyTargetResourceType] -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet -ReturnSetAction
								}								
							}
							elseif ($property -in @("clientAppTypes", "userRiskLevels", "signInRiskLevels")) {
								if (Compare-Object -ReferenceObject $resource.conditions.$property -DifferenceObject $definition.$property) {
									$change.Actions = @{"Set" = $definition.$property}
								}
							}
							elseif ($property -in @("builtInControls", "customAuthenticationFactors", "operator")) {
								if (Compare-Object -ReferenceObject $resource.grantControls.$property -DifferenceObject $definition.$property) {
									$change.Actions = @{"Set" = $definition.$property}
								}
							}
							elseif ($property -eq "termsOfUse") {
								$change.Actions = Compare-ResourceList -ReferenceList $resource.grantControls.$property `
									-DifferenceList $($definition.$property | ForEach-Object {Resolve-Agreement -InputReference $_ -Cmdlet $Cmdlet}) `
									-Cmdlet $PSCmdlet -ReturnSetAction
							}
							else {
								if ($definition.$property -ne $resource.$property) {
									$change.Actions = @{"Set" = $definition.$property}
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
					Write-PSFMessage -Level Warning -String 'TMF.Test.MultipleResourcesError' -StringValues $resourceName, $definition.displayName -Tag 'failed'
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
