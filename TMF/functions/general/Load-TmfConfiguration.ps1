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
				if ($componentDirectory.Name -notin $script:supportedComponents.Keys) {
					Write-PSFMessage -Level Warning -String "Load-TmfConfiguration.NotSupportedComponent" -StringValues $componentDirectory.Name, $configuration.Name
					continue
				}

				Write-Host "Adding $($componentDirectory.Name) from $($configuration.Name)"
				Get-ChildItem -Path $componentDirectory.FullName -File -Filter "*.json" | foreach {
					$content = Get-Content $_.FullName | ConvertFrom-Json
					if ($content.count -gt 0) {
						$content | foreach {
							$component = $_ | Add-Member -NotePropertyMembers @{sourceConfig = $configuration.Name} -PassThru | ConvertTo-PSFHashtable -Include $($script:supportedComponents[$componentDirectory.Name].Parameters.Keys)
							& $script:supportedComponents[$componentDirectory.Name] @component
						}
					}					 
				}
			}
		}
	}
	end
	{
	
	}
}
