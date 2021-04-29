function Test-TmfTenant
{
	<#
		.SYNOPSIS
			Tests activated configurations against the connected Tenant.
		
		.DESCRIPTION
			This command tests the desired configuration against the Tenant you are connected to.
			You can connect to a Tenant using Connect-MgGraph.

		.PARAMETER Exclude
			Exclude resources from testing.
			For example: -Exclude groups, users
	#>
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
