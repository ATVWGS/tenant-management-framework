function Load-TmfConfiguration
{
	<#
		.SYNOPSIS
			Loads the JSON files from the activated configurations.
		.DESCRIPTION
			Loads the JSON files from the activated configurations.
			All object definitions are stored in runtime variables.
	#>
	[CmdletBinding()]
	Param (
		[switch] $ReturnDesiredConfiguration
	)
	
	begin
	{	
		$configurationsToLoad = Get-TmfActiveConfiguration
		$script:desiredConfiguration = @{}
	}
	process
	{
		foreach ($configuration in $configurationsToLoad) {
			$resourceDirectories = Get-ChildItem $configuration.Path -Directory -Recurse
			foreach ($resourceDirectory in $resourceDirectories) {				
				if ($resourceDirectory.Name -notin $script:supportedResources.Keys) {
					Write-PSFMessage -Level Verbose -String "Load-TmfConfiguration.NotSupportedComponent" -StringValues $resourceDirectory.Name, $configuration.Name
					continue
				}
				if ("registerFunction" -notin $script:supportedResources[$resourceDirectory.Name].Keys) { continue }
				
				if (-Not $script:desiredConfiguration.ContainsKey($resourceDirectory.Name)) {
					$script:desiredConfiguration[$resourceDirectory.Name] = @()
				}				
				Get-ChildItem -Path $resourceDirectory.FullName -File -Filter "*.json" | foreach {
					$content = Get-Content $_.FullName | ConvertFrom-Json
					if ($content.count -gt 0) {
						$content | foreach {
							$resource = $_ | Add-Member -NotePropertyMembers @{sourceConfig = $configuration.Name} -PassThru | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceDirectory.Name]["registerFunction"].Parameters.Keys)
							# Calls the Register-Tmf(.*) function
							& $script:supportedResources[$resourceDirectory.Name]["registerFunction"] @resource -Cmdlet $PSCmdlet
						}
					}					 
				}
			}
		}
	}
	end
	{
		if ($ReturnDesiredConfiguration) {
			Get-TmfDesiredConfiguration
		}		
	}
}
