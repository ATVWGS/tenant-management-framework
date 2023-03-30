function Invoke-TmfCustomSecurityAttributeDefinition
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
		$resourceName = "customSecurityAttributeDefinitions"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "CustomSecurityAttributeDefinition"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		if ($SpecificResources) {
        	$testResults = Test-TmfCustomSecurityAttributeDefinition -SpecificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfCustomSecurityAttributeDefinition -Cmdlet $Cmdlet
		}

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/directory/customSecurityAttributeDefinitions"
					$requestMethod = "POST"
					$requestBody = @{
                        "attributeSet" = $result.DesiredConfiguration.attributeSet
						"name" = $result.DesiredConfiguration.name
						"description" = $result.DesiredConfiguration.description
						"isCollection" = $result.DesiredConfiguration.isCollection
                        "isSearchable" = $result.DesiredConfiguration.isSearchable
                        "status" = $result.DesiredConfiguration.status
                        "type" = $result.DesiredConfiguration.type
                        "usePreDefinedValuesOnly" = $result.DesiredConfiguration.usePreDefinedValuesOnly
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
					Write-PSFMessage -Level Warning -String 'TMF.Invoke.DeleteNotPossible' -StringValues $result.ResourceType, $result.ResourceName
				}
				"Update" {
					$requestUrl = "$script:graphBaseUrl/directory/customSecurityAttributeDefinitions/{0}" -f $result.GraphResource.Id
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
						try {
                            $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
                            Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                            Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
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
	{}
}