function Register-TmfAccessPackageResource
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[Parameter(Mandatory = $true)]
		[string] $resourceIdentifier,
		[string] $description = "Access Package Resource has been created with Tenant Management Framework",

		[ValidateSet("SharePointOnline", "AadApplication", "AadGroup")]
		[string] $originSystem = "AadGroup",
		[string] $catalog = "General",
		[ValidateSet("AadGroup", "Application", "Sharepoint Online Site")]
		[string] $resourceType = "AadGroup",
		[ValidateSet("Member", "Owner")]
		[string] $resourceRole = "Member",

		[bool] $present = $true,
		[string] $sourceConfig = "<Custom>",

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
			description = $description
			resourceIdentifier = $resourceIdentifier
			resourceType = $resourceType
			originSystem = $originSystem
			catalog = $catalog
			present = $present
		}

		@("resourceRole") | foreach {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
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
