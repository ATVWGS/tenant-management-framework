function Test-TmfTenant
{
	[CmdletBinding()]
	Param (
		[string[]] $Exclude
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfTenant" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -notin $Exclude} | Sort-Object {$_.Value.weight})) {
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Test-TmfTenant" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
				& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
			}			
		}
	}
	end
	{
	
	}
}
