function Invoke-TmfAuthenticationStrengthPolicy {
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
		$resourceName = "authenticationStrengthPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "authenticationStrengthPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
        
        $testResults = Test-TmfAuthenticationStrengthPolicy -Cmdlet $Cmdlet
		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl/policies/authenticationStrengthPolicies"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"description" = $result.DesiredConfiguration.description
                        "allowedCombinations" = $result.DesiredConfiguration.allowedCombinations
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

                    foreach ($change in $result.Changes) {
                        switch ($change.property) {
                            "allowedCombinations" {
                                $requestUrl = "$script:graphBaseUrl/policies/authenticationStrengthPolicies/{0}/updateAllowedCombinations" -f $result.GraphResource.Id
                                $requestMethod = "POST"
                                $requestBody = @{
                                    allowedCombinations = $result.DesiredConfiguration.allowedCombinations
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
                            "description" {
                                $requestUrl = "$script:graphBaseUrl/policies/authenticationStrengthPolicies/{0}" -f $result.GraphResource.Id
					            $requestMethod = "PATCH"
                                $requestBody = @{
                                    description = $result.DesiredConfiguration.description
                                }
                                try {
                                    $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                                    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                    Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
                                }
                                catch {
                                    Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                    throw $_
                                }
                            }
                        }
                    }
                }
                "Delete" {
                    $requestUrl = "$script:graphBaseUrl/policies/authenticationStrengthPolicies/{0}/`$ref" -f $result.GraphResource.Id
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
                "NoActionRequired" {}
                default {
					Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.ActionType
				}
            }
            Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
        }
    }

    end {}
}