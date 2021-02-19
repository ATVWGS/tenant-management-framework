function Activate-TmfConfiguration
{
	[CmdletBinding()]
	Param (
		[string] $Path,
		[switch] $Force
	)
	
	begin
	{
		$configurationFilePath = "{0}\configuration.json" -f $Path		
		if (!(Test-Path $configurationFilePath)) {
			Stop-PSFFunction -String "TMF.ConfigurationFileNotFound" -StringValues $configurationFilePath
			return
		}
		else {
			$configurationFilePath = Resolve-PSFPath -Provider FileSystem -Path $configurationFilePath -SingleItem
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
			Write-PSFMessage -Level Host -String "Activate-TMFConfiguration.RemovingAlreadyLoaded" -StringValues $configuration.Name, $configurationDirectory -Tag "Activation" -NoNewLine
			$script:activatedConfigurations = @($script:activatedConfigurations | Where-Object {$_.Name -ne $configuration.Name})
			Write-PSFHostColor -String ' [<c="green">✔</c>]'
		}		
		
		Write-PSFMessage -Level Host -String "Activate-TMFConfiguration.Activating" -StringValues $configuration.Name, $configurationDirectory -Tag "Activation" -NoNewLine
		Add-Member -InputObject $configuration -MemberType NoteProperty -Name "Path" -Value $configurationDirectory
		$script:activatedConfigurations += $configuration
		Write-PSFHostColor -String ' [<c="green">✔</c>]'

		Write-PSFMessage -Level Host -String "Activate-TMFConfiguration.Sort" -Tag "Activation" -NoNewLine
		$script:activatedConfigurations = @($script:activatedConfigurations | Sort-Object Weight)
		Write-PSFHostColor -String ' [<c="green">✔</c>]'
	}
	end
	{
	
	}
}
