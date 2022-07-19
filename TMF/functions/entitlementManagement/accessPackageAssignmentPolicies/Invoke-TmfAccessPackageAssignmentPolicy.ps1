function Invoke-TmfAccessPackageAssignmentPolicy
{
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessPackageAssignmentPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "AccessPackageAssignmentPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet

		function ConvertTo-RequestBody {
			Param (
				$TestResult				
			)

			$requestBody = @{						
				"displayName" = $TestResult.DesiredConfiguration.displayName
				"description" = $TestResult.DesiredConfiguration.description
				"accessPackageId" = $TestResult.DesiredConfiguration.accessPackageId()
				"canExtend" = $TestResult.DesiredConfiguration.canExtend
				"durationInDays" = $TestResult.DesiredConfiguration.durationInDays
			}

			foreach ($property in @("accessReviewSettings", "requestorSettings", "requestApprovalSettings")) {
				if ($property -in $TestResult.DesiredConfiguration.Properties()) {
					$requestBody[$property] = $TestResult.DesiredConfiguration.$property.PSObject.Copy()
					if ($property -eq "requestApprovalSettings") {
						if ($requestBody[$property]["approvalStages"]) {
							$requestBody[$property]["approvalStages"] = @($requestBody[$property]["approvalStages"].PSObject.Copy() | Foreach-Object {							
								$stage = $_
								"primaryApprovers", "escalationApprovers" | Where-Object { $_ -in $requestBody[$property]["approvalStages"].Keys } | Foreach-Object {								
									$stage[$_] = @($stage[$_] | Foreach-Object { $_.prepareBody() })
								}
								$stage
							})
						}
					}
					else {
						switch ($property) {
							"accessReviewSettings" { $userSetProperty = "reviewers" }
							"requestorSettings" { $userSetProperty = "allowedRequestors" }
						}

						if ($requestBody[$property].Keys -contains $userSetProperty) {
							$requestBody[$property][$userSetProperty] = @($requestBody[$property][$userSetProperty] | Foreach-Object { $_.prepareBody()	})
						}
					}
				}				
			}

			return $requestBody
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$testResults = Test-TmfAccessPackageAssignmentPolicy -Cmdlet $Cmdlet

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies"
					$requestMethod = "POST"
					$requestBody = ConvertTo-RequestBody -TestResult $result					

					try {
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
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
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Update" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies/{0}" -f $result.GraphResource.Id
					$requestMethod = "PUT"
					if ($result.Changes.count -gt 0) {
						$requestBody = ConvertTo-RequestBody -TestResult $result
	
						try {
							$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
							Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
							Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
						}
						catch {
							Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
							throw $_
						}
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
