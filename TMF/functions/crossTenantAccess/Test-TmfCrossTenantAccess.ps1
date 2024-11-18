function Test-TmfCrossTenantAccess
{
	[CmdletBinding()]
	Param ()
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
		$crossTenantAccessResources = @("crossTenantAccessPolicy", "crossTenantAccessDefaultSettings", "crossTenantAccessPartnerSettings")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfCrossTenantAccess" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -in $crossTenantAccessResources } | Sort-Object {$_.Value.weight})) {
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Test-TmfCrossTenantAccess" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
				& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
			}			
		}
	}
	end
	{
	
	}
}