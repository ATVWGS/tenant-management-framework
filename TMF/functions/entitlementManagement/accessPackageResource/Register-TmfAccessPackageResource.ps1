function Register-TmfAccessPackageResource
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,

		[ValidateSet("SharePointOnline", "AadApplication", "AadGroup")]
		[string] $originSystem = "AadGroup",
		[string] $catalog = "General",
		[string] $requestType = "AdminAdd",
		[ValidateSet("Member", "Owner")]
		[string] $resourceRole = "Member",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessPackageResources"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | ? {$_.displayName -eq $displayName}
		}

	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{		
			displayName = $displayName
			originSystem = $originSystem
			catalog = $catalog
			requestType = $resource
			resourceRole = $resourceRole
		}
	
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
	}
}
