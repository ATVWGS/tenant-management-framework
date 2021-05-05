function Test-TmfAccessPackage
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
		$resourceName = "accessPackages"
		$tenant = Get-MgOrganization -Property displayName, Id
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
				ResourceType = 'AccessPackage'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages?`$filter=displayName eq '{0}'&`$expand=accessPackageResourceRoleScopes(`$expand=accessPackageResourceRole,accessPackageResourceScope)" -f $definition.displayName)).Value
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
								"catalog" { <# Currently not possible to update! #> }
								"isRoleScopesVisible" { <# Currently not possible to update! #> }
								"accessPackageResourceRoleScopes" {
									$existingRoleScopes = @()
									if ($resource.accessPackageResourceRoleScopes.accessPackageResourceRole.originId) { $existingRoleScopes = $resource.accessPackageResourceRoleScopes.accessPackageResourceRole.originId }									
									$roleOriginIds = @($definition.accessPackageResourceRoleScopes.roleOriginId())
									$compare = Compare-Object -ReferenceObject  $existingRoleScopes -DifferenceObject $roleOriginIds

									if ($compare) {
										$change.Actions = @{}
										if ($compare.SideIndicator -contains "=>" -and -not $ReturnSetAction) {
											$change.Actions["Add"] = ($compare | Where-Object {$_.SideIndicator -eq "=>"}).InputObject
										}
										if ($compare.SideIndicator -contains "<=" -and -not $ReturnSetAction) {
											$change.Actions["Remove"] = ($compare | Where-Object {$_.SideIndicator -eq "<="}).InputObject
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