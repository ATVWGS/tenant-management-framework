function Activate-TmfConfiguration
{
	[CmdletBinding()]
	Param (
		[string] $Path,
		[switch] $Force
	)
	
	begin
	{
		$configurationFilePath = Resolve-PSFPath -Provider FileSystem -Path ("{0}\configuration.json" -f $Path) -SingleItem
		if (!(Test-Path $configurationFilePath)) {
			Stop-PSFFunction -String "Activate-TMFConfiguration.PathDoesNotExist" -StringValues $configurationFilePath
			return
		}

		$configuration = Get-Content $configurationFilePath | ConvertFrom-Json -ErrorAction Stop
		$configurationDirectory = Split-Path -Path "C:\Temp\TMFTestConfig\configuration.json" -Parent
		$configurationAlreadyActivated = $script:activatedConfigurations.Name -contains $configuration.Name
		
		if (!$Force -and $configurationAlreadyActivated) {
			Stop-PSFFunction -String "Activate-TMFConfiguration.AlreadyActivated" -StringValues $configuration.Name, $configurationFilePath
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		if ($Force -and $configurationAlreadyActivated) {
			$script:activatedConfigurations = @($script:activatedConfigurations | ? {$_.Name -ne $configuration.Name})
		}		
		
		Add-Member -InputObject $configuration -MemberType NoteProperty -Name "Path" -Value $configurationDirectory
		$script:activatedConfigurations += $configuration
		$script:activatedConfigurations = @($script:activatedConfigurations | Sort-Object Weight)
	}
	end
	{
	
	}
}
