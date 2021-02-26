function New-TmfConfiguration
{
	<#
		.SYNOPSIS
			Creates a empty Tenant configuration.
		
		.DESCRIPTION
			Creates a empty Tenant configuration.
			A Tenant configuration contains definitions for resources. Also Tenant settings can be defined in configuration files.
		
		.PARAMETER OutPath
			Where to create the configuration. Any path is possible.

		.PARAMETER Force
			Force the creation of the directory structure or overwrite an existing configuration.

		.PARAMETER DoNotAutoActivate
			Do not automatically activate configuration after creation.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $OutPath,
		[switch] $Force,
		[switch] $DoNotAutoActivate,

		[Parameter(Mandatory = $true)]
		[string] $Name,
		[int] $Weight = 50,
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
			Write-PSFMessage -Level Host -String "New-TMFConfiguration.OutPath.CreatingDirectory" -StringValues $OutPath -Tag "Preperation" -NoNewLine
			New-Item -Path $OutPath -ItemType Directory | Out-Null
			Write-PSFHostColor -String ' [<c="green">✔</c>]'
		}
		elseif (!$Force -and (Test-Path $configurationFilePath)) {
			Stop-PSFFunction -String "New-TMFConfiguration.OutPath.AlreadyExists" -StringValues $configurationFilePath
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		Write-PSFMessage -Level Host -String "New-TMFConfiguration.OutPath.CreatingStructure" -StringValues $OutPath -Tag "Creating" -NoNewLine
		Copy-Item -Path "$script:moduleRoot\internal\data\configuration\*" -Destination $OutPath -Recurse -Force
		Write-PSFHostColor -String ' [<c="green">✔</c>]'

		$configuration = [PSCustomObject] @{
			"Name" = $Name
			"Description" = $Description
			"Author" = $Author
			"Weight" = $Weight
			"Prerequisite" = $Prerequisite
		} 
		$configuration | ConvertTo-Json | Set-Content -Path $configurationFilePath
	}
	end
	{
		if (!$DoNotAutoActivate) {
			Activate-TmfConfiguration -Path $OutPath -Force
		}		
		Write-PSFMessage -Level Host -Message "Creation has finished! Have fun!" -NoNewLine
		Write-PSFHostColor -String ' [<c="green">✔</c>]'
	}
}
