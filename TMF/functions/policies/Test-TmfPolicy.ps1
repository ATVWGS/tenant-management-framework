function Test-TmfPolicy
{
	[CmdletBinding()]
	Param ()
		
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
		$policyResources = @("appManagementPolicies", "authenticationFlowsPolicies", "authenticationMethodsPolicies", "authenticationStrengthPolicies", "authorizationPolicies", "tenantAppManagementPolicies")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -in $policyResources} | Sort-Object {$_.Value.weight})) {
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Test-TmfPolicy" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
				& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet
			}			
		}
	}
	end
	{
	
	}
}