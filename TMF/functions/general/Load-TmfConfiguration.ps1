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

	)
	
	begin
	{
		$configurationsToLoad = Get-TmfActiveConfiguration
	}
	process
	{
		foreach ($configuration in $configurationsToLoad) {
			$componentDirectories = Get-ChildItem $configuration.Path -Directory
			foreach ($componentDirectory in $componentDirectories) {				
				if ($componentDirectory.Name -notin $script:supportedComponents) {
					Write-PSFMessage -Level Warning -String "Load-TmfConfiguration.NotSupportedComponent" -StringValues $componentDirectory.Name, $configuration.Name
					continue
				}
				Write-Host "Adding $($componentDirectory.Name) from $($configuration.Name)"
				$components = Get-ChildItem -Path $componentDirectory.FullName -File -Filter "*.json" | foreach {
					$dummy = Get-Content $_.FullName | ConvertFrom-Json -ErrorAction Stop
					return ($dummy | Add-Member -NotePropertyMembers @{sourceConfig = $configuration.Name} -PassThru)
				}				
				if (!$script:desiredConfiguration[$componentDirectory.Name]) {
					$script:desiredConfiguration[$componentDirectory.Name] = $components
				}
				else {
					$script:desiredConfiguration[$componentDirectory.Name] += $components | where {$_.displayName -notin $script:desiredConfiguration[$componentDirectory.Name].displayName}
				}
			}
		}
	}
	end
	{
	
	}
}
