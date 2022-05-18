function Test-TmfEntitlementManagement
{
	[CmdletBinding()]
	Param ()
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id
		$entitlementManagementResources = @("accessPackageCatalogs", "accessPackages", "accessPackageAssignmentPolicies", "accessPackageResources")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfEntitlementManagement" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -in $entitlementManagementResources} | Sort-Object {$_.Value.weight})) {
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Test-TmfEntitlementManagement" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
				& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
			}			
		}
	}
	end
	{
	
	}
}
