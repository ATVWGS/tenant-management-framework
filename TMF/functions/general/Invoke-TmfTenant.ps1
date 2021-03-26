function Invoke-TmfTenant
{
	Param (
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
