function Invoke-TmfCustomSecurityAttribute
{
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
		.DESCRIPTION
			This command combines the Invoke commands of all CustomSecurityAttribute resources.
			attributeSets, customSecurityAttributeDefinitions, customSecurityAttributeAllowedValues
	#>
	Param (
		[switch] $DoNotRequireTenantConfirm
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
		$customSecurityAttributeResources = @("attributeSets", "customSecurityAttributeDefinitions", "customSecurityAttributeAllowedValues")
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomSecurityAttribute" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		if (-Not $DoNotRequireTenantConfirm) {
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
		}		
		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.invokeFunction -and $_.Name -in $customSecurityAttributeResources} | Sort-Object {$_.Value.weight})) {			
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomSecurityAttribute" -String "TMF.StartingInvokeForResource" -StringValues $resourceType.Name					
				& $resourceType.Value["invokeFunction"] -Cmdlet $PSCmdlet
			}						
		}
	}
	end
	{
	
	}
}
