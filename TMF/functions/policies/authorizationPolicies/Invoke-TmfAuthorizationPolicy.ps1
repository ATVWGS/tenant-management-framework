function Invoke-TmfAuthorizationPolicy {
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
		$resourceName = "authorizationPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "authorizationPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
        
        $testResults = Test-TmfAuthorizationPolicy -Cmdlet $Cmdlet
		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $requestMethod = "PATCH"
                    $requestUrl = "$script:graphBaseUrl/policies/authorizationPolicy/authorizationPolicy"
                    $requestBody = @{
                        "allowInvitesFrom" = $result.DesiredConfiguration.allowInvitesFrom
                        "allowedToSignUpEmailBasedSubscriptions" =  $result.DesiredConfiguration.allowedToSignUpEmailBasedSubscriptions
                        "allowedToUseSSPR" = $result.DesiredConfiguration.allowedToUseSSPR
                        "allowedEmailVerifiedUsersToJoinOrganization" = $result.DesiredConfiguration.allowedEmailVerifiedUsersToJoinOrganization
                        "blockMsolPowerShell" =  $result.DesiredConfiguration.blockMsolPowerShell
                        "guestUserRoleId" = $result.DesiredConfiguration.guestUserRoleId
                        "permissionGrantPolicyIdsAssignedToDefaultUserRole" = $result.DesiredConfiguration.permissionGrantPolicyIdsAssignedToDefaultUserRole
                        "defaultUserRolePermissions" = $result.DesiredConfiguration.defaultUserRolePermissions
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