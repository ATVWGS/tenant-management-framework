function Test-TmfCustomSecurityAttribute
{
	[CmdletBinding()]
	Param ()
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id
		$customSecurityAttributeResources = @("attributeSets", "customSecurityAttributeDefinitions", "customSecurityAttributeAllowedValues")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfCustomSecurityAttribute" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -in $customSecurityAttributeResources} | Sort-Object {$_.Value.weight})) {
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Test-TmfCustomSecurityAttribute" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
				& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
			}			
		}
	}
	end
	{
	
	}
}