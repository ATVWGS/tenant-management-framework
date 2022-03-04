function Invoke-TmfConditionalAccessPolicy
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
		$resourceName = "conditionalAccessPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "ConditionalAccessPolicy"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		if ($SpecificResources) {
        	$testResults = Test-TmfConditionalAccessPolicy -SpecificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfConditionalAccessPolicy -Cmdlet $Cmdlet
		}

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identity/conditionalAccess/policies"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"state" = $result.DesiredConfiguration.state
					}
					try {						
						foreach ($property in ($result.DesiredConfiguration.Properties() | Where-Object {$_ -notin @("displayName", "state", "present", "sourceConfig")})) {
							$requestBody[$property] = $result.DesiredConfiguration.$property
						}
						
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
					$requestUrl = "$script:graphBaseUrl/identity/conditionalAccess/policies/{0}" -f $result.GraphResource.Id
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
					$requestUrl = "$script:graphBaseUrl/identity/conditionalAccess/policies/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
					try {
						foreach ($change in $result.Changes) {
							foreach ($action in $change.Actions.Keys) {
								switch ($action) {
									"Set" {										
										$requestBody[$change.property] = $change.Actions[$action]
									}									
								}
							}
						}

						if ($requestBody.Keys -gt 0) {
							$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
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
		Load-TmfConfiguration -Cmdlet $Cmdlet
	}
}
