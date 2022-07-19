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
		[string[]] $SpecificResources,
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
		$definitions = @()
		if ($SpecificResources) {
			foreach ($specificResource in $SpecificResources) {

				if ($specificResource -match "\*") {
					if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -like $specificResource}) {
						$definitions += $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -like $specificResource}
					}
					else {
						Write-PSFMessage -Level Warning -String 'TMF.Error.SpecificResourceNotExists' -StringValues $filter -Tag 'failed'
						$exception = New-Object System.Data.DataException("$($specificResource) not exists in Desired Configuration for $($resourceName)!")
						$errorID = "SpecificResourceNotExists"
						$category = [System.Management.Automation.ErrorCategory]::NotSpecified
						$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
						$cmdlet.ThrowTerminatingError($recordObject)
					}
				}
				else {
					if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $specificResource}) {
						$definitions += $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $specificResource}
					}
					else {
						Write-PSFMessage -Level Warning -String 'TMF.Error.SpecificResourceNotExists' -StringValues $filter -Tag 'failed'
						$exception = New-Object System.Data.DataException("$($specificResource) not exists in Desired Configuration for $($resourceName)!")
						$errorID = "SpecificResourceNotExists"
						$category = [System.Management.Automation.ErrorCategory]::NotSpecified
						$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
						$cmdlet.ThrowTerminatingError($recordObject)
					}
				}
			}
			$definitions = $definitions | Sort-Object -Property displayName -Unique
		}
		else {
			$definitions = $script:desiredConfiguration[$resourceName]
		}

		foreach ($definition in $definitions) {
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
			
			try {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages?`$filter=(displayName eq '{0}')&`$expand=accessPackageResourceRoleScopes(`$expand=accessPackageResourceRole,accessPackageResourceScope)" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName))).Value

				if (("oldNames" -in $definition.Properties()) -and (-not ($resource))) {
					foreach ($oldName in $definition.oldNames) {
						$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages?`$filter=(displayName eq '{0}')&`$expand=accessPackageResourceRoleScopes(`$expand=accessPackageResourceRole,accessPackageResourceScope)" -f [System.Web.HttpUtility]::UrlEncode($oldName))).Value
						if ($resource) {break}
					}
				}
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
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig", "oldNames"})) {
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
