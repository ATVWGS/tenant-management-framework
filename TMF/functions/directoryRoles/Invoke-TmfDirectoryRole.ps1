function Invoke-TmfDirectoryRole {
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
		$resourceName = "DirectoryRoles"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "directoryRole"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
		if ($SpecificResources) {
        	$testResults = Test-TmfDirectoryRole -SpecificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfDirectoryRole -Cmdlet $Cmdlet
		}

        foreach ($result in $testResults) {

            switch ($result.ActionType) {
                "Change members" {

					$roleMembers = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/{0}/members" -f $result.DesiredConfiguration.roleID)).Value

					if ($roleMembers) {

						Compare-Object $result.DesiredConfiguration.memberIDs $roleMembers.id | ForEach-Object {

							$item = $_

							switch ($item.SideIndicator) {
								"<=" {
									$requestUrl = "$script:graphBaseUrl/directoryRoles/$($result.DesiredConfiguration.roleID)/members/`$ref"
									$requestMethod = "POST"
									$requestBody = @{						
										"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($item.InputObject)"
									}
									try {
										$requestBody = $requestBody | ConvertTo-Json
										Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
										Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
									}
									catch {
										Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
										throw $_
									}
								}
								"=>" {
									$requestUrl = "$script:graphBaseUrl/directoryRoles/$($result.DesiredConfiguration.roleID)/members/$($item.InputObject)/`$ref"
									$requestMethod = "DELETE"
									try {
										Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
										Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
									}
									catch {
										Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
										throw $_
									}
								}
							}
						}
					}
					else {
						foreach ($item in $result.DesiredConfiguration.memberIDs) {
							$requestUrl = "$script:graphBaseUrl/directoryRoles/$($result.DesiredConfiguration.roleID)/members/`$ref"
							$requestMethod = "POST"
							$requestBody = @{						
								"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($item)"
							}
							try {
								$requestBody = $requestBody | ConvertTo-Json
								Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
								Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
							}
							catch {
								Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
								throw $_
							}
						}
					}
                }
                "Activate" {
					$roleTemplateID = Resolve-DirectoryRoleTemplate -InputReference $result.DesiredConfiguration.displayName -Cmdlet $PSCmdlet
                    $requestUrl = "$script:graphBaseUrl/directoryRoles"
					$requestMethod = "POST"
					$requestBody = @{
						"roleTemplateId"= $roleTemplateID
					}
                    try {
						$requestBody = $requestBody | ConvertTo-Json
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}

					if ($result.DesiredConfiguration.memberIDs) {
						$roleID = Resolve-DirectoryRole -InputReference $result.DesiredConfiguration.displayName -Cmdlet $PSCmdlet
						foreach ($item in $result.DesiredConfiguration.memberIDs) {
							$requestUrl = "$script:graphBaseUrl/directoryRoles/$($roleID)/members/`$ref"
								$requestMethod = "POST"
								$requestBody = @{						
									"@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($item)"
								}
								try {
									$requestBody = $requestBody | ConvertTo-Json
									Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
									Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
								}
								catch {
									Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
									throw $_
								}
						}
					}
                }
                "NoActionRequired" {}
                default {
                    Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                }
            }
            Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
        }

    }
}