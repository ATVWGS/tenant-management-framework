function Invoke-TmfAccessPackageAssignementPolicy
{
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessPackageAssignementPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "AccessPackageAssignementPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$testResults = Test-TmfAccessPackageAssignementPolicy -Cmdlet $Cmdlet

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"description" = $result.DesiredConfiguration.description
						"accessPackageId" = $result.DesiredConfiguration.accessPackageId()
					}

					if ($result.DesiredConfiguration.Properties() -contains "accessReviewSettings") {
						$accessReviewSettings = $result.DesiredConfiguration.accessReviewSettings
						if ($accessReviewSettings.reviewers) {
							$accessReviewSettings.reviewers = @($accessReviewSettings.reviewers | Foreach-Object {
								$_.prepareBody()
							})
						}
						$requestBody["accessReviewSettings"] = $accessReviewSettings
					}

					if ($result.DesiredConfiguration.Properties() -contains "requestorSettings") {
						$requestorSettings = $result.DesiredConfiguration.requestorSettings
						if ($requestorSettings.allowedRequestors) {
							$requestorSettings.allowedRequestors = @($requestorSettings.allowedRequestors | Foreach-Object {
								$_.prepareBody()
							})
						}
						$requestBody["requestorSettings"] = $requestorSettings
					}

					if ($result.DesiredConfiguration.Properties() -contains "requestApprovalSettings") {
						$requestApprovalSettings = $result.DesiredConfiguration.requestApprovalSettings
						$requestApprovalSettings.approvalStages = @($requestApprovalSettings.approvalStages | Foreach-Object {							
							$stage = $_
							$stage.primaryApprovers = @($stage.primaryApprovers | Foreach-Object {
								$_.prepareBody()
							})
							$stage.escalationApprovers = @($stage.escalationApprovers | Foreach-Object {
								$_.prepareBody()
							})
							$stage
						})
						$requestBody["requestApprovalSettings"] = $requestApprovalSettings
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
				"Delete" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies/{0}" -f $result.GraphResource.Id
					$requestMethod = "DELETE"
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						#Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Update" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
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
						#Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
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
