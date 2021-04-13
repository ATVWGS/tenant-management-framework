function Deactivate-TmfConfiguration
{
	<#
		.SYNOPSIS
			Deactivate already TMF configuration.

		.DESCRIPTION
			Deactivate configurations you don't want to apply to your tenant. Only activated configuration will be considered when testing or invoking configurations.

		.PARAMETER Name
			Provide the name of the TMF configuration to deactivate.

		.PARAMETER Path
			Provide a path to the TMF configuration to deactivate.

		.PARAMETER All
			Deactivate all configurations currently activated.

		.EXAMPLE
			PS> Deactivate-TmfConfiguration -Path "C:\Temp\SomeConfiguration"
			
			Deactivates the configuration in path C:\Temp\SomeConfiguration.
		
		.EXAMPLE
			PS> Deactivate-TmfConfiguration -Name "SomeConfiguration"
			
			Deactivates the configuration with name "SomeConfiguration".
		
		.EXAMPLE
			PS> Deactivate-TmfConfiguration -All
			
			Deactivates all configurations.
	#>
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "Name")]
		[string] $Name,

		[Parameter(Mandatory = $true, ParameterSetName = "Path")]
		[string] $Path,

		[Parameter(ParameterSetName = "All")]
		[switch] $All
	)
	
	begin
	{
		if ($All) {
			return
		}

		if ($PSCmdlet.ParameterSetName -eq "Path") {
			if ($Path -notmatch ".*configuration.json$") {
				$configurationFilePath = "{0}\configuration.json" -f $Path	
			}

			if (!(Test-Path $configurationFilePath)) {
				Stop-PSFFunction -String "TMF.ConfigurationFileNotFound" -StringValues $configurationFilePath
				return
			}

			$configurationFilePath = Resolve-PSFPath -Provider FileSystem -Path $configurationFilePath -SingleItem
			$Name = (Get-Content $configurationFilePath | ConvertFrom-Json -ErrorAction Stop).Name
		}		
		
		if ($script:activatedConfigurations.Name -notcontains $Name) {
			Stop-PSFFunction -String "Deactivate-TMFConfiguration.NotActivated" -StringValues $Name
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		if ($All) {
			Write-PSFMessage -Level Host -String "Deactivate-TMFConfiguration.DeactivatingAll" -NoNewLine
			$script:activatedConfigurations = @()
			$script:desiredConfiguration = @{}
			Write-PSFHostColor -String ' [<c="green">DONE</c>]'
		}
		else {
			Write-PSFMessage -Level Host -String "Deactivate-TMFConfiguration.Deactivating" -StringValues $Name -NoNewLine
			$script:activatedConfigurations = @($script:activatedConfigurations | Where-Object {$_.Name -ne $Name})			
			Write-PSFHostColor -String ' [<c="green">DONE</c>]'
		}		
	}
	end
	{
		Load-TmfConfiguration
	}
}
