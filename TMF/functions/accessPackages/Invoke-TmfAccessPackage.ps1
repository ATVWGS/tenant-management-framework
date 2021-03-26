function Invoke-TmfAccessPackages
{
	[CmdletBinding()]
	Param ( )
		
	
	begin
	{
		$componentName = "accessPackages"
		if (!$script:desiredConfiguration[$componentName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "AccessPackage"
			return
		}
		Test-GraphConnection -Cmdlet $PSCmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$testResults = Test-TmfAccessPackage -Cmdlet $PSCmdlet

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl1 = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs"

					$requestBody1 = @{
            			"displayName" = $result.DesiredConfiguration.catalog.displayName
            			"description" = $result.DesiredConfiguration.catalog.description
            			"isExternallyVisible" = $result.DesiredConfiguration.catalog.isExternallyVisible
					}

					$requestUrl2 = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages"

					$requestBody2 = @{
            			"catalogId" = Resolve-AccessPackageCatalog -AccesPackageCatalogReference $result.DesiredConfiguration.catalogName
            			"displayName" = $result.DesiredConfiguration.displayName
            			"description" = $result.DesiredConfiguration.description
            			"isHidden" = $result.DesiredConfiguration.isHidden
            			"isRoleScopesVisible" = $result.DesiredConfiguration.isRoleScopesVisible
					}

					$requestUrl3 = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies"

					$requestBody3 = [PSCustomObject]@{
						"displayName" = $result.DesiredConfiguration.policy.displayName
						"description"= $result.DesiredConfiguration.policy.description
						"canExtend"= $result.DesiredConfiguration.policy.canExtend
						"durationInDays"= $result.DesiredConfiguration.policy.durationInDays
						"accessReviewSettings"= @{
							"isEnabled" = $true
							"recurrenceType" = "monthly"
							"reviewerType" = "Reviewers"
							"durationInDays" = 14
							"reviewers" = $result.DesiredConfiguration.policy.reviewers
						"requestorSettings"= @{
							"scopeType"= $result.DesiredConfiguration.policy.scopeType
							"acceptRequests"= $result.DesiredConfiguration.policy.acceptRequests
							"allowedRequestors"= $result.DesiredConfiguration.policy.requestorSettings.allowedRequestors
						}
						"requestApprovalSettings"= @{
							"isApprovalRequired"= $true
							"isApprovalRequiredForExtension"= $false
							"isRequestorJustificationRequired"= $true
							"approvalMode"= "SingleStage"
							"approvalStages"= @{
									"approvalStageTimeOutInDays"= 14
									"isApproverJustificationRequired"= $false
									"isEscalationEnabled"= $false
									"escalationTimeInMinutes"= 0
									"primaryApprovers"= @([PSCustomObject]@{
											"@odata.type"= $result.DesiredConfiguration.policy.primaryApprovers.odataType
											"isBackup"= $true
											"id"= $result.DesiredConfiguration.policy.primaryApprovers
											#Resolve-Group -GroupReference $result.DesiredConfiguration.requestorSettings.allowedRequestors
									})
									"escalationApprovers"= @([PSCustomObject]@{
										"@odata.type"= $result.DesiredConfiguration.policy.primaryApprovers.odataType
										"isBackup"= $true
										"id"= $result.DesiredConfiguration.policy.primaryApprovers
										#Resolve-Group -GroupReference $result.DesiredConfiguration.requestorSettings.allowedRequestors
									})
								}
							}
						"questions"= $result.DesiredConfiguration.policy.questions
						}
					}

					$requestMethod = "POST"

					try {
					#"policy", "accessPackage", , "catalog" | foreach {
					#	if ($result.DesiredConfiguration.Properties() -contains "$_") {
					#		$requestBody[$_] = $result.DesiredConfiguration.$_
				#			}
					#	}
						
						$requestBody1 = $requestBody1 | ConvertTo-Json -ErrorAction Stop
						$requestBody2 = $requestBody2 | ConvertTo-Json -ErrorAction Stop
						$requestBody3 = $requestBody3 | ConvertTo-Json -ErrorAction Stop

						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl1, $requestBody1
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl1 -Body $requestBody1 | Out-Null

						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl2, $requestBody2
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl2 -Body $requestBody2 | Out-Null

						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl3, $requestBody3
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl3 -Body $requestBody3 | Out-Null
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Delete" {

					# Access Package Policy löschen / Access Package löschen / Catalog wenn empty
					$requestUrl = "$script:graphBaseUrl/identity/conditionalAccess/namedLocations/{0}" -f $result.GraphResource.Id
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
					
					# Update Access Package / Update Access Package Policy / Update Catalog
					$requestUrl = "$script:graphBaseUrl/identity/conditionalAccess/namedLocations/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
					try {
						foreach ($change in $result.Changes) {						
							switch ($change.Property) {								
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
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
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
		
	} 
}
