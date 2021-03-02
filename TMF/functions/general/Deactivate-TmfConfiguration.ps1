function Deactivate-TmfConfiguration
{
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
			$configUpdate = $script:desiredConfiguration.GetEnumerator() | Where-Object {$_.Value.sourceConfig -eq $Name} 
			$configUpdate | foreach {
				$script:desiredConfiguration[$_.Key] = $script:desiredConfiguration[$_.Key] | Where-Object {$_.sourceConfig -ne $Name}
			}
			$script:activatedConfigurations = @($script:activatedConfigurations | Where-Object {$_.Name -ne $Name})			
			Write-PSFHostColor -String ' [<c="green">DONE</c>]'
		}		
	}
	end
	{
	
	}
}
