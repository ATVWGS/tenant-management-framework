function Export-TmfTenant
{
	<#
		.SYNOPSIS
			Exports all supported resource type resources from the connected Tenant.
		
		.DESCRIPTION
			This command exports all supported resource type resources from the Tenant you are connected to.
			You can connect to a Tenant using Connect-MgGraph.

		.PARAMETER Exclude
			Exclude resources from export.
			For example: -Exclude groups, users

		.PARAMETER resourceTypes
			Perform export for entered resource types only.
			For example: -resourceTypes groups,roleAssignments
        
        .PARAMETER OutPath
            Root folder to write export; when omitted objects are returned.
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
        [string] $OutPath
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
		Write-PSFMessage -Level Host -FunctionName "Export-TmfTenant" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
		if ($resourceTypes) {
            if ($OutPath) {
                foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.exportFunction -and $_.Name -in $resourceTypes} | Sort-Object {$_.Value.weight})) {
                    Write-PSFMessage -Level Host -FunctionName "Export-TmfTenant" -String 'TMF.StartingExportForResource' -StringValues $resourceType.Name
                    & $resourceType.Value["exportFunction"] -Cmdlet $PSCmdlet -OutPath $OutPath
                }
            }
            else {
                foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.exportFunction -and $_.Name -in $resourceTypes} | Sort-Object {$_.Value.weight})) {
                    Write-PSFMessage -Level Host -FunctionName "Export-TmfTenant" -String 'TMF.StartingExportForResource' -StringValues $resourceType.Name
                    & $resourceType.Value["exportFunction"] -Cmdlet $PSCmdlet
                }
            }
			
		}
		else {
            if ($OutPath) {
                foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.exportFunction -and $_.Name -notin $Exclude} | Sort-Object {$_.Value.weight})) {
                    Write-PSFMessage -Level Host -FunctionName "Export-TmfTenant" -String 'TMF.StartingExportForResource' -StringValues $resourceType.Name
                    & $resourceType.Value["exportFunction"] -Cmdlet $PSCmdlet -OutPath $OutPath
                }
            }
            else {
                foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Value.exportFunction -and $_.Name -notin $Exclude} | Sort-Object {$_.Value.weight})) {
                    Write-PSFMessage -Level Host -FunctionName "Export-TmfTenant" -String 'TMF.StartingExportForResource' -StringValues $resourceType.Name
                    & $resourceType.Value["exportFunction"] -Cmdlet $PSCmdlet
                }
            }
			
		}		
	}
	end
	{
	
	}
}
