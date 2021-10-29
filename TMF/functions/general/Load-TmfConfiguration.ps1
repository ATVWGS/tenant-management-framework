function Load-TmfConfiguration
{
	<#
		.SYNOPSIS
			Loads the JSON files from the activated configurations.
		.DESCRIPTION
			Loads the JSON files from the activated configurations.
			All object definitions are stored in runtime variables.
		.PARAMETER ReturnDesiredConfiguration
			Returns the desired configuration after loading from activated configurations.
	#>
	[CmdletBinding()]
	Param (
		[switch] $ReturnDesiredConfiguration
	)
	
	begin
	{
		function Register-Resources {
			Param (
				[object[]] $Resources,
				[string] $ResourceType
			)
			if ($Resources.Count -gt 0) {
				$Resources | Foreach-Object {
					$resource = $_ | Add-Member -NotePropertyMembers @{sourceConfig = $configuration.Name} -PassThru | ConvertTo-PSFHashtable -Include $($script:supportedResources[$ResourceType]["registerFunction"].Parameters.Keys)
					# Calls the Register-Tmf(.*) function
					& $script:supportedResources[$ResourceType]["registerFunction"] @resource -Cmdlet $PSCmdlet
				}
			}
		}

		$configurationsToLoad = Get-TmfActiveConfiguration
		$script:desiredConfiguration = @{}
	}
	process
	{
		# Register stringMappings first
		# The stringMappings required for the template functions to work.
		foreach ($configuration in $configurationsToLoad) {
			$stringMappingsDirectory = "{0}stringMappings" -f $configuration.Path
			if (-Not (Test-Path $stringMappingsDirectory)) { continue }

			Get-ChildItem -Path $stringMappingsDirectory -File -Filter "*.json" | ForEach-Object {
				$content = Get-Content $_.FullName -Encoding UTF8 | Out-String | ConvertFrom-Json				
				Register-Resources -Resources $content -ResourceType "stringMappings"								 
			}
		}

		# Register all other resources
		foreach ($configuration in $configurationsToLoad) {
			$resourceDirectories = Get-ChildItem $configuration.Path -Directory -Recurse			

			foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Name -ne "stringMappings"} | Sort-Object {$_.Value.weight}).Name) {					
				$resourceDirectory = "{0}{1}" -f $configuration.Path, $resourceType
				if (-Not (Test-Path $resourceDirectory)) { continue }

				Get-ChildItem -Path $resourceDirectory -File -Filter "*.json" | ForEach-Object {
					$content = Get-Content $_.FullName -Encoding UTF8 | Out-String
					$content = Assert-TemplateFunctions -InputTemplate $content | ConvertFrom-Json
					Register-Resources -Resources $content -ResourceType $resourceType
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
