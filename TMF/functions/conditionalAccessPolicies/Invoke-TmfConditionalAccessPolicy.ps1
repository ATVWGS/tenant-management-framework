function Invoke-TmfConditionalAccessPolicy
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
		$resourceName = "conditionalAccessPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "ConditionalAccessPolicy"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet

		$resolveFunctionMapping = @{
			"Users" = (Get-Command Resolve-User)
			"Groups" = (Get-Command Resolve-Group)
			"Applications" = (Get-Command Resolve-Application)
			"Roles" = (Get-Command Resolve-DirectoryRoleTemplate)
			"Locations" = (Get-Command Resolve-NamedLocation)
			"Platforms" = "DirectCompare"
		}
		$conditionPropertyRegex = [regex]"^(include|exclude)($($resolveFunctionMapping.Keys -join "|"))$"
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$testResults = Test-TmfConditionalAccessPolicy -Cmdlet $Cmdlet

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identity/conditionalAccess/policies"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"state" = $result.DesiredConfiguration.state
						"conditions" = @{}
					}
					try {
						
						foreach ($property in ($result.DesiredConfiguration.Properties() | Where-Object {$_ -notin @("displayName", "state", "present", "sourceConfig")})) {
							$conditionPropertyMatch = $conditionPropertyRegex.Match($property)
							if ($conditionPropertyMatch.Success) {
								# Condition properties								
								if ($conditionPropertyMatch.Groups[2].Value -in @("Users", "Groups", "Roles")) {
									$conditionChildProperty = "users"	
								}
								else {
									$conditionChildProperty = $conditionPropertyMatch.Groups[2].Value.ToLower()
								}
								
								if (-Not $requestBody["conditions"][$conditionChildProperty]) { $requestBody["conditions"][$conditionChildProperty] = @{} }
								if ($resolveFunctionMapping[$conditionPropertyMatch.Groups[2].Value] -eq "DirectCompare") {
									$requestBody["conditions"][$conditionChildProperty][$property] = @($result.DesiredConfiguration.$property)
								}
								else {
									$requestBody["conditions"][$conditionChildProperty][$property] = @($result.DesiredConfiguration.$property | ForEach-Object { & $resolveFunctionMapping[$conditionPropertyMatch.Groups[2].Value] -InputReference $_})								
								}								
							}
							elseif ($property -in @("clientAppTypes", "signInRiskLevels", "userRiskLevels")) {
								$requestBody["conditions"][$property] = $result.DesiredConfiguration.$property
							}
							elseif ($property -in @("operator", "builtInControls", "customAuthenticationFactors", "termsOfUse")) {
								if (-Not $requestBody["grantControls"]) { $requestBody["grantControls"] = @{} }								
								if ($property -eq "termsOfUse") {
									$requestBody["grantControls"][$property] = @($result.DesiredConfiguration.$property | ForEach-Object {Resolve-Agreement -InputReference $_ -Cmdlet $Cmdlet})
								}
								else {
									$requestBody["grantControls"][$property] = $result.DesiredConfiguration.$property
								}
							}
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
							$conditionPropertyMatch = $conditionPropertyRegex.Match($change.property)
							foreach ($action in $change.Actions.Keys) {
								switch ($action) {
									"Set" {
										if ($conditionPropertyMatch.Success) {
											if (-Not $requestBody["conditions"]) { $requestBody["conditions"] = @{} }
											# Condition properties								
											if ($conditionPropertyMatch.Groups[2].Value -in @("Users", "Groups", "Roles")) {
												$conditionChildProperty = "users"	
											}
											else {
												$conditionChildProperty = $conditionPropertyMatch.Groups[2].Value.ToLower()
											}
											
											if (-Not $requestBody["conditions"][$conditionChildProperty]) { $requestBody["conditions"][$conditionChildProperty] = @{} }
											$requestBody["conditions"][$conditionChildProperty][$change.property] = @($change.Actions[$action])
										}
										elseif ($change.property -in @("clientAppTypes", "signInRiskLevels", "userRiskLevels")) {
											if (-Not $requestBody["conditions"]) { $requestBody["conditions"] = @{} }
											$requestBody["conditions"][$change.property] = $change.Actions[$action]
										}
										elseif ($change.property -in @("operator", "builtInControls", "customAuthenticationFactors", "termsOfUse")) {
											if (-Not $requestBody["grantControls"]) { $requestBody["grantControls"] = @{} }
											$requestBody["grantControls"][$change.property] = $change.Actions[$action]
										}
										else {
											$requestBody[$change.property] = $change.Actions[$action]
										}
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
		
	}
}
