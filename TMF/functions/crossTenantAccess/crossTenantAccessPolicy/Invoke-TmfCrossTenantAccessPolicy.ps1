function Invoke-TmfCrossTenantAccessPolicy
{
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
		[switch] $Confirm = $false,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "crossTenantAccessPolicy"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "CrossTenantAccessPolicy"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		if (-not $Confirm) {
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCrossTenantAccessPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCrossTenantAccessPolicy" -String "TMF.Invoke.Confirmed" -StringValues "all crossTenantAccessPolicy configurations"
        	$testResults = Test-TmfCrossTenantAccessPolicy -RawOutput -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfCrossTenantAccessPolicy -RawOutput -Cmdlet $Cmdlet
		}
		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Update" {
					$requestUrl = "$script:graphBaseUrl/policies/crossTenantAccessPolicy"
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