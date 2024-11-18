function Invoke-TmfCrossTenantAccessPartnerSetting
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
		$resourceName = "crossTenantAccessPartnerSettings"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "CrossTenantAccessPartnerSetting"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

        $testResults = Test-TmfCrossTenantAccessPartnerSetting -Cmdlet $Cmdlet

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl/policies/crossTenantAccessPolicy/partners"
					$requestMethod = "POST"
					$requestBody = @{
                        "tenantId" = $result.DesiredConfiguration.tenantId
                        "automaticUserConsentSettings" = $result.DesiredConfiguration.automaticUserConsentSettings
                        "b2bCollaborationInbound" = $result.DesiredConfiguration.b2bCollaborationInbound
                        "b2bCollaborationOutbound" = $result.DesiredConfiguration.b2bCollaborationOutbound
                        "b2bDirectConnectInbound" = $result.DesiredConfiguration.b2bDirectConnectInbound
                        "b2bDirectConnectOutbound" = $result.DesiredConfiguration.b2bDirectConnectOutbound
                        "inboundTrust" = $result.DesiredConfiguration.inboundTrust
						"tenantRestrictions" = $result.DesiredConfiguration.tenantRestrictions
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
				"Update" {
					$requestUrl = "$script:graphBaseUrl/policies/crossTenantAccessPolicy/partners/{0}" -f $result.GraphResource.tenantId
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
                            $requestBody = $requestBody | ConvertTo-Json -Depth 8 -ErrorAction Stop
                            Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                            Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
                        }
                        catch {
                            Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                            throw $_
                        }
					}
				}
                "Delete" {
                    $requestUrl = "$script:graphBaseUrl/policies/crossTenantAccessPolicy/partners/{0}" -f $result.GraphResource.tenantId
					$requestMethod = "DELETE"
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl | Out-Null
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
	{}
}