function Invoke-TmfRoleManagement
{
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
		.DESCRIPTION
			This command combines the Invoke commands of all RoleManagement resources.
			roleAssignments, roleDefinitions, roleManagementPolicies
	#>
	Param (
		[ValidateSet('AzureResources', 'AzureAD')]
        [string] $scope,
		[switch] $DoNotRequireTenantConfirm
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
		$roleManagementResources = @("roleAssignments", "roleDefinitions", "roleManagementPolicies")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Invoke-TmfRoleManagement" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		if (-Not $DoNotRequireTenantConfirm) {
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
		}		
		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.invokeFunction -and $_.Name -in $roleManagementResources} | Sort-Object {$_.Value.weight})) {			
			if ($script:desiredConfiguration[$resourceType.Name]) {
				if ($scope) {
					Write-PSFMessage -Level Host -FunctionName "Invoke-TmfRoleManagement" -String "TMF.StartingInvokeForScopedResource" -StringValues $resourceType.Name, $scope
					& $resourceType.Value["invokeFunction"] -scope $scope -Cmdlet $PSCmdlet
				}
				else {
					Write-PSFMessage -Level Host -FunctionName "Invoke-TmfRoleManagement" -String "TMF.StartingInvokeForResource" -StringValues $resourceType.Name					
					& $resourceType.Value["invokeFunction"] -Cmdlet $PSCmdlet
				}
				Start-Sleep 5			
			}						
		}
	}
	end
	{
	
	}
}
