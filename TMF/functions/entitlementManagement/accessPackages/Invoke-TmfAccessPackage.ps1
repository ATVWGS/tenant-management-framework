function Invoke-TmfAccessPackage
{
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessPackages"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "AccessPackage"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		if ($SpecificResources) {
        	$testResults = Test-TmfAccessPackage -SpecificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfAccessPackage -Cmdlet $Cmdlet
		}

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"description" = $result.DesiredConfiguration.description
						"isHidden" = $result.DesiredConfiguration.isHidden						
						"isRoleScopesVisible" = $result.DesiredConfiguration.isRoleScopesVisible
						"catalogId" = (Resolve-AccessPackageCatalog -InputReference $result.DesiredConfiguration.catalog)
					}
					try {
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						$accessPackage = Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}

					<# Create accessPackageResourceRoleScopes #>
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}/accessPackageResourceRoleScopes" -f $accessPackage.Id
					foreach ($roleScope in $result.DesiredConfiguration.accessPackageResourceRoleScopes) {						
						$requestBody = @{
							"accessPackageResourceRole" = @{
								"originId" = $roleScope.roleOriginId()
								"displayName" = $roleScope.resourceRole
								"originSystem" = $roleScope.originSystem
								"accessPackageResource" = @{
									"id" = Resolve-AccessPackageResource -InputReference $roleScope.originId() -CatalogId $roleScope.catalogId()
									"resourceType" = $roleScope.resourceType
									"originId" = $roleScope.originId()
									"originSystem" = $roleScope.originSystem
								}
							}
							"accessPackageResourceScope" = @{
								"originId" = $roleScope.originId()
								"originSystem" = $roleScope.originSystem
							}
						}
						try {
							$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
							Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
							Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
						}
						catch {
							Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
							throw $_
						}
					}
				}
				"Delete" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}" -f $result.GraphResource.Id
					$requestMethod = "DELETE"
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Update" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
					foreach ($change in $result.Changes) {						
						switch ($change.Property) {
							"catalogId" { <# Currently not possible to update! #> }
							"isRoleScopesVisible" { <# Currently not possible to update! #> }
							"accessPackageResourceRoleScopes" {
								$url = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}/accessPackageResourceRoleScopes" -f $result.GraphResource.Id
								foreach ($action in $change.Actions.Keys) {									
									switch ($action) {										
										"Add" {											
											$method = "POST"
											$change.Actions[$action] | Foreach-Object {
												$roleOriginId = $_
												$roleScope = $result.DesiredConfiguration.accessPackageResourceRoleScopes | Where-Object {$_.roleOriginId() -eq $roleOriginId}
												$body = @{
													"accessPackageResourceRole" = @{
														"originId" = $roleScope.roleOriginId()
														"displayName" = $roleScope.resourceRole
														"originSystem" = $roleScope.originSystem
														"accessPackageResource" = @{
															"id" = Resolve-AccessPackageResource -InputReference $roleScope.originId() -CatalogId $roleScope.catalogId()
															"resourceType" = $roleScope.resourceType
															"originId" = $roleScope.originId()
															"originSystem" = $roleScope.originSystem
														}
													}
													"accessPackageResourceScope" = @{
														"originId" = $roleScope.originId()
														"originSystem" = $roleScope.originSystem
													}
												} | ConvertTo-Json -ErrorAction Stop
												Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body
												Invoke-MgGraphRequest -Method $method -Uri $url -Body $body | Out-Null
											}
										}
										"Remove" {
											$method = "DELETE"											
											$change.Actions[$action] | ForEach-Object {												
												Write-PSFMessage -Level Warning -Message "The Microsoft Graph accessPackageResourceRoleScopes endpoint does not support DELETE at the moment. Please remove the Resource Role manually from the Access Package."
												<#
												$roleOriginId = $_
												$roleScope = $result.GraphResource.accessPackageResourceRoleScopes | Where-Object {$_.accessPackageResourceRole.originId -eq $roleOriginId}
												$body = @{
													"id" = $roleScope["id"]
													"accessPackageResourceRole" = $roleScope["accessPackageResourceRole"]
													"accessPackageResourceScope" = $roleScope["accessPackageResourceScope"]
												} | ConvertTo-Json -ErrorAction Stop
												Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body
												Invoke-MgGraphRequest -Method $method -Uri $url -Body $body | Out-Null
												#>
											}
										}
									}
								}
							}
							default {
								foreach ($action in $change.Actions.Keys) {
									switch ($action) {
										"Set" { $requestBody[$change.Property] = $change.Actions[$action] }
									}
								}
							}
						}							
					}

					if ($requestBody.Keys -gt 0) {
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
					}
				}
				"NoActionRequired" { }
				default {
					Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.ActionType
				}				
			}
			Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
		}		
	}
	end
	{
		Load-TmfConfiguration -Cmdlet $Cmdlet
	}
}
