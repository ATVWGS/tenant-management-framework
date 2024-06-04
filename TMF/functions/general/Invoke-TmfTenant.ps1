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

		.PARAMETER resourceTypes
			Perform invoking for entered resource types only.
			For example: -resourceTypes groups,roleAssignments

		.PARAMETER DoNotRequireTenantConfirm
			Do not ask for confirmation when invoking configurations.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Exclude')]
	Param (
		[Parameter(ParameterSetName = 'Exclude')]
		[ValidateScript({
			if ($_ -in $script:supportedResources.Keys) { return $true}
			throw "'$_' is not in the set of the supported values: $($script:supportedResources.Keys -join ', ')"

		})]
		[string[]] $Exclude,
		[Parameter(ParameterSetName = 'resourceTypes')]
		[ValidateScript({
			if ($_ -in $script:supportedResources.Keys) { return $true}
			throw "'$_' is not in the set of the supported values: $($script:supportedResources.Keys -join ', ')"

		})]
		[string[]] $resourceTypes,
		[Parameter(ParameterSetName = 'Exclude')]
		[Parameter(ParameterSetName = 'resourceTypes')]
		[switch] $DoNotRequireTenantConfirm
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value		
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
		
		if ($resourceTypes) {
			foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.invokeFunction -and $_.Name -in $resourceTypes} | Sort-Object {$_.Value.weight})) {			
				if ($script:desiredConfiguration[$resourceType.Name]) {
					Write-PSFMessage -Level Host -FunctionName "Invoke-TmfTenant" -String "TMF.StartingInvokeForResource" -StringValues $resourceType.Name					
					& $resourceType.Value["invokeFunction"] -Cmdlet $PSCmdlet
				}						
			}
		}
		else {
			foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.invokeFunction -and $_.Name -notin $Exclude} | Sort-Object {$_.Value.weight})) {			
				if ($script:desiredConfiguration[$resourceType.Name]) {
					Write-PSFMessage -Level Host -FunctionName "Invoke-TmfTenant" -String "TMF.StartingInvokeForResource" -StringValues $resourceType.Name					
					& $resourceType.Value["invokeFunction"] -Cmdlet $PSCmdlet
				}						
			}
		}		
	}
	end
	{
	
	}
}
