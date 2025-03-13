function Invoke-TmfAuthenticationFlowsPolicy {
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
		$resourceName = "authenticationFlowsPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "authenticationFlowsPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
        if (-not $Confirm) {
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationFlowsPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
            Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationFlowsPolicy" -String "TMF.Invoke.Confirmed" -StringValues "all authenticationFlowsPolicy configurations"
            $testResults = Test-TmfAuthenticationFlowsPolicy -RawOutput -Cmdlet $Cmdlet
        }
        else {
            $testResults = Test-TmfAuthenticationFlowsPolicy -RawOutput -Cmdlet $Cmdlet
        }
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $requestMethod = "PATCH"
                    $requestUrl = "$script:graphBaseUrl/policies/authenticationFlowsPolicy"
                    $requestBody = @{
                        "selfServiceSignUp" = @{
                            "isEnabled" = $result.DesiredConfiguration.selfServiceSignUp.isEnabled
                        }
                    }
                    $requestBody = $requestBody | ConvertTo-Json -Depth 5

                    try {
                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                        Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                        Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                    }
                    catch {
                        Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                        throw $_
                    }
                }
                "NoActionRequired" {}
            }
        }
    }

    end {}
}