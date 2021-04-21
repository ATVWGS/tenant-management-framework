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
		$Cmdlet = $PSCmdlet,
		[switch] $PassThru
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
			resourceRole = $resourceRole
			originSystem = $originSystem
			catalog = $catalog
			present = $present
		}
		
		Add-Member -InputObject $object -MemberType NoteProperty -Name "catalogId" -Value (Resolve-AccessPackageCatalog -InputReference $catalog -Cmdlet $Cmdlet) -Force		
		switch ($resourceType) { # Resolve originId (eg. get the ObjectId of a group resource)
			"AadGroup" {
				 $originId = Resolve-Group -InputReference $resourceIdentifier
			}
		}
		Add-Member -InputObject $object -MemberType NoteProperty -Name "originId" -Value $originId
		Add-Member -InputObject $object -MemberType NoteProperty -Name "roleOriginId" -Value ("{0}_{1}" -f $resourceRole, $originId) -Force		
		<# NOT REQUIRED ATM
		@() | foreach {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
		} #>
	
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
	}
	end 
	{
		if ($PassThru) {
			$object
		}		
	}
}
