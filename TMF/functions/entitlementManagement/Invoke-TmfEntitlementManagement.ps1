function Invoke-TmfEntitlementManagement
{
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
		.DESCRIPTION
			This command combines the Invoke commands of all Entitlement Management resources.
			accessPackageCatalogs, accessPackages, accessPackageAssignmentPolicies, accessPackageResources
	#>
	Param (
		[switch] $DoNotRequireTenantConfirm
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id
		$entitlementManagementResources = @("accessPackageCatalogs", "accessPackages", "accessPackageAssignmentPolicies", "accessPackageResources")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Invoke-TmfEntitlementManagement" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		if (-Not $DoNotRequireTenantConfirm) {
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
		}		
		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.invokeFunction -and $_.Name -in $entitlementManagementResources} | Sort-Object {$_.Value.weight})) {			
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfEntitlementManagement" -String "TMF.StartingInvokeForResource" -StringValues $resourceType.Name					
				& $resourceType.Value["invokeFunction"] -Cmdlet $PSCmdlet
			}						
		}
	}
	end
	{
	
	}
}
