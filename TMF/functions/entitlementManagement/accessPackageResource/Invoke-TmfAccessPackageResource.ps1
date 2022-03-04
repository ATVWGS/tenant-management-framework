function Invoke-TmfAccessPackageResource
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
		$resourceName = "accessPackageResources"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "AccessPackageResouce"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$testResults = Test-TmfAccessPackageResource -Cmdlet $Cmdlet

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageResourceRequests"
					$requestMethod = "POST"

					$requestBody = @{
						"accessPackageResource" = @{
							"displayName" = $result.DesiredConfiguration.displayName
							"description" = $result.DesiredConfiguration.description
							"resourceType" = $result.DesiredConfiguration.resourceType
							"originSystem" = $result.DesiredConfiguration.originSystem
							"originId" = $result.DesiredConfiguration.originId()
						}						
						"justification" = "Resource is required for an Access Package managed by the Tenant Managment Framework"						
						"requestType" = "AdminAdd"
						"catalogId" = $result.DesiredConfiguration.catalogId()
					}
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
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageResourceRequests"
					$requestMethod = "POST"

					$requestBody = @{
						"accessPackageResource" = @{
							"displayName" = $result.DesiredConfiguration.displayName
							"description" = $result.DesiredConfiguration.description
							"resourceType" = $result.DesiredConfiguration.resourceType
							"originSystem" = $result.DesiredConfiguration.originSystem
							"originId" = $result.DesiredConfiguration.originId()
						}						
						"justification" = "Resource is not longer required for an Access Package managed by the Tenant Managment Framework"						
						"requestType" = "AdminRemove"
						"catalogId" = $result.DesiredConfiguration.catalogId()
					}
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
