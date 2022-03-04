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
		[switch] $ReturnDesiredConfiguration,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		function Register-Resource {
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
			$stringMappingsDirectory = "{0}\stringMappings" -f $configuration.Path
			if (-Not (Test-Path $stringMappingsDirectory)) { continue }

			Get-ChildItem -Path $stringMappingsDirectory -File -Filter "*.json" | ForEach-Object {
				Write-Progress -Activity "Loading string mappings from $($_.Name)"
				$content = Get-Content $_.FullName -Encoding UTF8 | Out-String | ConvertFrom-Json				
				Register-Resource -Resources $content -ResourceType "stringMappings"				
			}
		}

		# Register all other resources
		foreach ($configuration in $configurationsToLoad) {
			Write-Progress -Id 0 -Activity "Activating $($configuration.Name)"
			
			foreach ($resourceType in ($script:supportedResources.GetEnumerator() | Where-Object {$_.Name -ne "stringMappings"} | Sort-Object {$_.Value.weight})) {
				$resourceTypeName = $resourceType.Name
				Write-Progress -Id 1 -Activity "Loading $resourceTypeName" -Status "Starting" -PercentComplete 0
				
				if ($resourceType.Value["parentType"]) {
					$resourceDirectory = "{0}\{1}\{2}" -f $configuration.Path, $resourceType.Value["parentType"], $resourceTypeName
				}
				else {
					$resourceDirectory = "{0}\{1}" -f $configuration.Path, $resourceTypeName
				}
				
				if (-Not (Test-Path $resourceDirectory)) { continue; Write-Progress -Id 1 -Activity "Loading $resourceTypeName" -Completed }

				$counter = 0
				$definitionFiles = Get-ChildItem -Path $resourceDirectory -File -Filter "*.json"
				$definitionFiles | ForEach-Object {
					Write-Progress -Id 1 -Activity "Loading $resourceTypeName" -CurrentOperation "Reading file $($_.Name)" -PercentComplete (($counter / $definitionFiles.count) * 100)
					$content = Get-Content $_.FullName -Encoding UTF8 | Out-String
					$content = Assert-TemplateFunctions -InputTemplate $content | ConvertFrom-Json					
					Register-Resource -Id 1 -Resources $content -ResourceType $resourceTypeName					
					$counter++
				}
				Write-Progress -Id 1 -Activity "Loading $resourceTypeName" -Completed
			}

			Write-Progress -Id 0 -Activity "Activating $($configuration.Name)" -Completed
		}
	}
	end
	{
		if ($ReturnDesiredConfiguration) {
			Get-TmfDesiredConfiguration
		}		
	}
}
