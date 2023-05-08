function Invoke-TmfTenantAppManagementPolicy {
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
		$resourceName = "tenantAppManagementPolicy"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "tenantAppManagementPolicy"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
        
        $testResults = Test-TmfTenantAppManagementPolicy -Cmdlet $Cmdlet
        		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $requestUrl = "$script:graphBaseUrl/policies/defaultAppManagementPolicy"
                    $requestMethod = "PATCH"
                    $requestBody = @{						
                        "displayName" = $result.DesiredConfiguration.displayName
                        "description" = $result.DesiredConfiguration.description
                        "isEnabled" = $result.DesiredConfiguration.isEnabled
                        "applicationRestrictions" = $result.DesiredConfiguration.applicationRestrictions
                        "servicePrincipalRestrictions" = $result.DesiredConfiguration.servicePrincipalRestrictions
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