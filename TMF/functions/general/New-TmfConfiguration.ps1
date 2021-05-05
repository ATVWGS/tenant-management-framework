function New-TmfConfiguration
{
	<#
		.SYNOPSIS
			Creates a empty TMF Tenant configuration.
		
		.DESCRIPTION
			Creates a empty TMF Tenant configuration.
			A configuration contains definitions for resources.
		
		.PARAMETER OutPath
			Where to create the configuration. Any path is possible.

		.PARAMETER Force
			Force the creation of the directory structure or overwrite an existing configuration.

		.PARAMETER DoNotAutoActivate
			Do not automatically activate configuration after creation.

		.PARAMETER Name
			The name of the new configuration.

		.PARAMETER Description
			A description for the configuration. For example to explain which tenants this configuration should be applied to.
		
		.PARAMETER Weight
			The weight of the configuration. This is considered when loading the desired configuration.
			Configurations with a higher weight overwrite configurations (If they have resources with the same displayName or name) that have been loaded earlier.

		.PARAMETER Author
			Define who created this configuration or who is responsible for changes.
		
		.PARAMETER Prerequisite
			On which other configurations this configuration depends.

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
			Write-PSFMessage -Level Host -String "New-TMFConfiguration.OutPath.CreatingDirectory" -StringValues $OutPath -NoNewLine
			New-Item -Path $OutPath -ItemType Directory | Out-Null
			Write-PSFHostColor -String ' [<c="green">DONE</c>]'
		}
		elseif (!$Force -and (Test-Path $configurationFilePath)) {
			Stop-PSFFunction -String "New-TMFConfiguration.OutPath.AlreadyExists" -StringValues $configurationFilePath
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		Write-PSFMessage -Level Host -String "New-TMFConfiguration.OutPath.CreatingStructure" -StringValues $OutPath -NoNewLine
		Copy-Item -Path "$script:moduleRoot\internal\data\configuration\*" -Destination $OutPath -Recurse -Force
		Write-PSFHostColor -String ' [<c="green">DONE</c>]'

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
		if (Test-PSFFunctionInterrupt) { return }

		if (!$DoNotAutoActivate) {
			Activate-TmfConfiguration -ConfigurationPaths $OutPath -Force
		}		
		Write-PSFMessage -Level Host -Message "Creation has finished! Have fun!" -NoNewLine
		Write-PSFHostColor -String ' [<c="green">DONE</c>]'
	}
}
