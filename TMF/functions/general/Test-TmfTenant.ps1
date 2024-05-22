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

		.PARAMETER resourceTypes
			Perform testing for entered resource types only.
			For example: -resourceTypes groups,roleAssignments
	#>
	[CmdletBinding()]
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
		[string[]] $resourceTypes
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Test-TmfTenant" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
		if ($resourceTypes) {
			foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -in $resourceTypes} | Sort-Object {$_.Value.weight})) {
				if ($script:desiredConfiguration[$resourceType.Name]) {
					Write-PSFMessage -Level Host -FunctionName "Test-TmfTenant" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
					& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
				}			
			}
		}
		else {
			foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.testFunction -and $_.Name -notin $Exclude} | Sort-Object {$_.Value.weight})) {
				if ($script:desiredConfiguration[$resourceType.Name]) {
					Write-PSFMessage -Level Host -FunctionName "Test-TmfTenant" -String "TMF.StartingTestForResource" -StringValues $resourceType.Name
					& $resourceType.Value["testFunction"] -Cmdlet $PSCmdlet | Beautify-TmfTestResult
				}			
			}
		}		
	}
	end
	{
	
	}
}
