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
				"allowedTargetScope" = $TestResult.DesiredConfiguration.allowedTargetScope
				"accessPackage" = @{
					"id" = $TestResult.DesiredConfiguration.accessPackageId()
				}
			}

			foreach ($property in @("expiration","reviewSettings", "requestorSettings", "requestApprovalSettings", "specificAllowedTargets", "automaticRequestSettings")) {
				switch ($property) {
					"specificAllowedTargets" {
						if (($Testresult.DesiredConfiguration | Get-Member).name -contains $property) {
							$requestBody[$property] = @($TestResult.DesiredConfiguration.$property | Foreach-Object { $_.prepareBody()	})
						}						
					}
					"requestApprovalSettings" {
						if ((Get-Member -InputObject $TestResult.DesiredConfiguration).Name -contains $property) {
							$requestBody[$property] = $TestResult.DesiredConfiguration.$property.PSObject.Copy()
							if ($requestBody[$property]["stages"]) {
								$requestBody[$property]["stages"] = @($requestBody[$property]["stages"].PSObject.Copy() | Foreach-Object {							
									$stage = $_
									"primaryApprovers", "escalationApprovers", "fallbackPrimaryApprovers", "fallbackEscalationApprovers" | Where-Object { $_ -in $requestBody[$property]["stages"].Keys } | Foreach-Object {								
										$stage[$_] = @($stage[$_] | Foreach-Object { $_.prepareBody() })
									}
									$stage
								})
							}
						}
					}
					"reviewSettings" {
						if ((Get-Member -InputObject $TestResult.DesiredConfiguration).Name -contains $property) {
							$requestBody[$property] = $TestResult.DesiredConfiguration.$property.PSObject.Copy()
							if ($TestResult.DesiredConfiguration.$property.primaryReviewers) {
								$requestBody[$property]["primaryReviewers"] = @($TestResult.DesiredConfiguration.$property.primaryReviewers | Foreach-Object {
									$_.prepareBody()
								})
							}
							if ($TestResult.DesiredConfiguration.$property.fallbackReviewers) {
								$requestBody[$property]["fallbackReviewers"] = @($TestResult.DesiredConfiguration.$property.fallbackReviewers | Foreach-Object {
									$_.prepareBody()
								})
							}
						}
					}
					"requestorSettings" {
						if ((Get-Member -InputObject $TestResult.DesiredConfiguration).Name -contains $property) {
							$requestBody[$property] = $TestResult.DesiredConfiguration.$property.PSObject.Copy()
							if ($TestResult.DesiredConfiguration.$property.onBehalfRequestors) {
								$requestBody[$property]["onBehalfRequestors"] = @($TestResult.DesiredConfiguration.$property.onBehalfRequestors | ForEach-Object {
									$_.prepareBody()
								})
							}
						}
					}
					default {
						if ((Get-Member -InputObject $TestResult.DesiredConfiguration).Name -contains $property) {
							$requestBody[$property] = $TestResult.DesiredConfiguration.$property.PSObject.Copy()
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
					$requestUrl = "$script:graphBaseUrl1/identityGovernance/entitlementManagement/assignmentPolicies"
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
					$requestUrl = "$script:graphBaseUrl1/identityGovernance/entitlementManagement/assignmentPolicies/{0}" -f $result.GraphResource.Id
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
					$requestUrl = "$script:graphBaseUrl1/identityGovernance/entitlementManagement/assignmentPolicies/{0}" -f $result.GraphResource.Id
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
