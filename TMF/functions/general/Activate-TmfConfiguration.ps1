function Activate-TmfConfiguration
{
	<#
		.SYNOPSIS
			Activates already created TMF configurations.

		.DESCRIPTION
			Activate configurations you want to apply to your tenant. An activated configuration will be considered when testing or invoking configurations.

		.PARAMETER ConfigurationPaths
			One or more paths to Tenant Management Framework configuration directories can be provided.

		.PARAMETER Force
			Overwrite already loaded configurations.

		.PARAMETER DoNotLoad
			Do not load resource definitions after activating.

		.EXAMPLE
			PS> Activate-TmfConfiguration -ConfigurationPaths "C:\Temp\SomeConfiguration"
			
			Activates the configuration in path C:\Temp\SomeConfiguration.

	#>
	[CmdletBinding()]
	Param (
		[string[]] $ConfigurationPaths,
		[switch] $Force,
		[switch] $DoNotLoad
	)
	
	begin
	{
		$configurationsToActivate = @()
		#region Prepare to activate
		foreach ($path in $ConfigurationPaths) {
			$configuration = [PSCustomObject] @{
				filePath = "{0}\configuration.json" -f $path
				directoryPath = $path
				alreadyActivated = $false
			}

			#region Check if configuration.json exists
			if (!(Test-Path $configuration.filePath)) {
				Stop-PSFFunction -String "TMF.ConfigurationFileNotFound" -StringValues $configuration.filePath
				return
			}
			else {
				# Clean configuration path
				$configuration.filePath = Resolve-PSFPath -Provider FileSystem -Path $configuration.filePath -SingleItem
			}
			#endregion

			#region Load configuration.json
			$contentDummy = Get-Content $configuration.filePath | ConvertFrom-Json -ErrorAction Stop
			$contentDummy | Get-Member -MemberType NoteProperty | ForEach-Object {
				Add-Member -InputObject $configuration -MemberType NoteProperty -Name $_.Name -Value $contentDummy.$($_.Name)
			}
			$configuration.alreadyActivated = $script:activatedConfigurations.Name -contains $configuration.Name
			#endregion			
			
			if (!$Force -and $configuration.alreadyActivated) {
				Write-PSFMessage -Level Warning -String "Activate-TMFConfiguration.AlreadyActivated" -StringValues $configuration.Name, $configuration.filePath
			}

			$configurationsToActivate += $configuration
		}
		#endregion
		
		#region Check prerequisites
		foreach ($configuration in $configurationsToActivate) {			
			if ($configuration.Prerequisite.Count -gt 0) {				
				foreach ($prereq in $configuration.Prerequisite) {
					$prereqMet = $false
					if ($prereq.contains("||")) {						
						$prereq.split("||") | Foreach-Object {
							if ($_.trim() -in $configurationsToActivate.Name -or $_.trim() -in (Get-TmfActiveConfiguration).Name) { $prereqMet = $true }
						}
					}
					else {
						if ($prereq -in $configurationsToActivate.Name -or $prereq -in (Get-TmfActiveConfiguration).Name) {
							$prereqMet = $true
						}
					}
					if (-Not $prereqMet) {
						Stop-PSFFunction -String "TMF.PrerequisiteNotActivated" -StringValues $configuration.Name, $prereq
						return
					}
				}
			}
		}
		#endregion
	}
	process
	{		
		if (Test-PSFFunctionInterrupt) { return }

		foreach ($configuration in $configurationsToActivate) {
			if ($Force -and $configuration.alreadyActivated) {
				Write-PSFMessage -Level Host -String "Activate-TMFConfiguration.RemovingAlreadyLoaded" -StringValues $configuration.Name, $configuration.directoryPath -NoNewLine
				$script:activatedConfigurations = @($script:activatedConfigurations | Where-Object {$_.Name -ne $configuration.Name})
				Write-PSFHostColor -String ' [<c="green">DONE</c>]'
			}
			elseif (!$Force -and $configuration.alreadyActivated) {
				continue
			}

			Write-PSFMessage -Level Host -String "Activate-TMFConfiguration.Activating" -StringValues $configuration.Name, $configuration.filePath -NoNewLine			
			$script:activatedConfigurations += $configuration | Select-Object Name, @{Name = "Path"; Expression = {Resolve-Path $_.directoryPath}}, Description, Author, Weight, Prerequisite
			Write-PSFHostColor -String ' [<c="green">DONE</c>]'
		}

		Write-PSFMessage -Level Host -String "Activate-TMFConfiguration.Sort" -NoNewLine
		$script:activatedConfigurations = @($script:activatedConfigurations | Sort-Object Weight)
		Write-PSFHostColor -String ' [<c="green">DONE</c>]'
	}
	end
	{
		if (-Not $DoNotLoad) {
			Load-TmfConfiguration -Cmdlet $PSCmdlet
		}
	}
}
