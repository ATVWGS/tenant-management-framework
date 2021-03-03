function Invoke-TmfGroup
{
	[CmdletBinding()]
	Param (
	
	)
	
	begin
	{
		if (!$script:desiredConfiguration["groups"]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "Group"
			return
		}
		Test-GraphConnection -Cmdlet $PSCmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		$testResults = Test-TmfGroup

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestBody = @{
						"description" = $result.DesiredConfiguration.description
						"displayName" = $result.DesiredConfiguration.displayName
						"mailNickname" = $result.DesiredConfiguration.mailNickname
						"groupTypes" = $result.DesiredConfiguration.groupTypes
						"mailEnabled" = $result.DesiredConfiguration.mailEnabled
						"securityEnabled" = $result.DesiredConfiguration.securityEnabled
					}
					try {
						if ($result.DesiredConfiguration.Properties() -contains "members") {
							$requestBody["members@odata.bind"] = @($result.DesiredConfiguration.members | foreach {"$script:graphBaseUrl/users/{0}" -f (Resolve-User -UserReference $_ -Cmdlet $PSCmdlet).Id})
						}
						if ($result.DesiredConfiguration.Properties() -contains "owners") {
							$requestBody["owners@odata.bind"] = @($result.DesiredConfiguration.owners | foreach {"$script:graphBaseUrl/users/{0}" -f (Resolve-User -UserReference $_ -Cmdlet $PSCmdlet).Id})
						}
						if ($result.DesiredConfiguration.Properties() -contains "membershipRule") {
							$requestBody["membershipRule"] = $result.DesiredConfiguration.membershipRule
							$requestBody["membershipRuleProcessingState"] = "On"
						}
						
						Write-Host ($requestBody | ConvertTo-Json -ErrorAction Stop)						
						Invoke-MgGraphRequest -Method POST -Uri "$script:graphBaseUrl/groups" -Body ($requestBody | ConvertTo-Json -ErrorAction Stop)
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Delete" {					
					try {
						Invoke-MgGraphRequest -Method DELETE -Uri ("$script:graphBaseUrl/groups/{0}" -f $result.GraphResource.Id)
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Update" {
					$requestBody = @{}
					try {
						foreach ($change in $result.Changes) {						
							switch ($change.Property) {
								"members" {
									foreach ($action in $change.Actions.Keys) {
										switch ($action) {
											"Add" {
												$change.Actions[$action] | foreach {
													$body = @{ "@odata.id" = "$script:graphBaseUrl/users/{0}" -f $_ }
													Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/groups/{0}/members/`$ref" -f $result.GraphResource.Id) -Body ($body | ConvertTo-Json -ErrorAction Stop)
												}
											}
											"Remove" {
												$change.Actions[$action] | foreach {
													Invoke-MgGraphRequest -Method DELETE -Uri ("$script:graphBaseUrl/groups/{0}/members/{1}/`$ref" -f $result.GraphResource.Id, $_)
												}
											}
										}
									}
								}
								"owners" {
									foreach ($action in $change.Actions.Keys) {
										switch ($action) {
											"Add" {
												$change.Actions[$action] | foreach {
													$body = @{ "@odata.id" = "$script:graphBaseUrl/users/{0}" -f $_ }
													Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/groups/{0}/owners/`$ref" -f $result.GraphResource.Id) -Body ($body | ConvertTo-Json -ErrorAction Stop)
												}
											}
											"Remove" {
												$change.Actions[$action] | foreach {
													Invoke-MgGraphRequest -Method DELETE -Uri ("$script:graphBaseUrl/groups/{0}/owners/{1}/`$ref" -f $result.GraphResource.Id, $_)
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
						Write-Host ($requestBody | ConvertTo-Json)
						Invoke-MgGraphRequest -Method PATCH -Uri ("$script:graphBaseUrl/groups/{0}" -f $result.GraphResource.Id) -Body ($requestBody | ConvertTo-Json -ErrorAction Stop)
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
