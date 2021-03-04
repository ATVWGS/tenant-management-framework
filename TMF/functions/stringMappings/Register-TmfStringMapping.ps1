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
		$componentName = "stringMappings"
		if (!$script:desiredConfiguration[$componentName]) {
			$script:desiredConfiguration[$componentName] = @()
		}

		if ($script:desiredConfiguration[$componentName].name -contains $name) {			
			$alreadyLoaded = $script:desiredConfiguration[$componentName] | ? {$_.name -eq $name}
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
			$script:desiredConfiguration[$componentName][$script:desiredConfiguration[$componentName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$componentName] += $object
		}		
	}
}
