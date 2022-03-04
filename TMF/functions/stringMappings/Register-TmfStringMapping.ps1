function Register-TmfStringMapping
{
	[CmdletBinding(DefaultParameterSetName = 'IPRanges')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $name,

		[Parameter(Mandatory = $true)]
		[string] $replace,		

		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{		
		$resourceName = "stringMappings"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].name -contains $name) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.name -eq $name}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			name = $name
			replace = $replace
			sourceConfig = $sourceConfig
		}

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}		
	}
}
