function Invoke-TmfTenant
{
	<#
		.SYNOPSIS
			Invoke required actions for all configured resources.
		
		.DESCRIPTION
			This command applies the desired configuration to the Tenant you are connected to.
			You can connect to a Tenant using Connect-MgGraph.

		.PARAMETER Exclude
			Exclude resources from invoking.
			For example: -Exclude groups, users

		.PARAMETER DoNotRequireTenantConfirm
			Do not ask for confirmation when invoking configurations.
	#>
	Param (
		[ValidateSet({$script:supportedResources.Keys()})]
		[string[]] $Exclude,
		[switch] $DoNotRequireTenantConfirm
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id		
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Invoke-TmfTenant" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id		
		if (-Not $DoNotRequireTenantConfirm) {
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
		}		
		
		foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.invokeFunction -and $_.Name -notin $Exclude} | Sort-Object {$_.Value.weight})) {			
			if ($script:desiredConfiguration[$resourceType.Name]) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfTenant" -String "TMF.StartingInvokeForResource" -StringValues $resourceType.Name					
				& $resourceType.Value["invokeFunction"] -Cmdlet $PSCmdlet
			}						
		}
	}
	end
	{
	
	}
}
