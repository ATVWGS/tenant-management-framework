function Test-TmfRoleManagement
{
	[CmdletBinding()]
	Param (
		[ValidateSet('AzureResources', 'AzureAD')]
        [string] $scope
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
		$roleManagementResources = @("roleAssignments", "roleDefinitions", "roleManagementPolicies")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfRoleManagement" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -in $roleManagementResources} | Sort-Object {$_.Value.weight})) {
			if ($script:desiredConfiguration[$resourceType.Name]) {
				if ($scope) {
					Write-PSFMessage -Level Host -FunctionName "Test-TmfRoleManagement" -String "TMF.StartingTestForScopedResource" -StringValues $resourceType.Name,$scope
					& $resourceType.Value["testFunction"] -scope $scope -Cmdlet $PSCmdlet | Beautify-TmfTestResult
				}
				else {
					Write-PSFMessage -Level Host -FunctionName "Test-TmfRoleManagement" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
					& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
				}
			}			
		}
	}
	end
	{
	
	}
}