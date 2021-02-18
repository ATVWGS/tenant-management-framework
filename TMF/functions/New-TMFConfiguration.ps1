function New-TMFConfiguration
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $OutPath,
		[switch] $Force,
		[switch] $AutoLoad,

		[Parameter(Mandatory = $true)]
		[string] $Name,
		[string] $Description = "<insert description here>",
		[string] $Author = "<author>",
		[string[]] $Prerequisite = @()
	)
	
	begin
	{
		$configurationFilePath = "{0}\configuration.json" -f $OutPath

		if (!$Force -and !(Test-Path $OutPath)) {
			Stop-PSFFunction -String "New-TMFConfiguration.OutPath.PathDoesNotExist" -StringValues $OutPath
			return
		}
		elseif ($Force -and !(Test-Path $OutPath)) {
			Write-PSFMessage -Level Host -String "New-TMFConfiguration.OutPath.CreatingDirectory" -StringValues $OutPath
			New-Item -Path $OutPath -ItemType Directory | Out-Null
		}
		elseif (!$Force -and (Test-Path $configurationFilePath)) {
			Stop-PSFFunction -String "New-TMFConfiguration.OutPath.AlreadyExists" -StringValues $configurationFile
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		Write-Host "Bla"
		[PSCustomObject]@{
			"Name" = $Name
			"Description" = $Description
			"Author" = $Author
			"Prerequisite" = $Prerequisite
		} | ConvertTo-Json | Set-Content -Path $configurationFilePath
	}
	end
	{
	
	}
}
