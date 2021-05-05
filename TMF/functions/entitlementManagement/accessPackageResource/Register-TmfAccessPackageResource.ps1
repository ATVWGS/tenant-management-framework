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
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
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
		
		<# NOT REQUIRED ATM
		@() | foreach {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
		} #>
	
		Add-Member -InputObject $object -MemberType ScriptMethod -Name "catalogId" -Value {
			Resolve-AccessPackageCatalog -InputReference $this.catalog
		}
		Add-Member -InputObject $object -MemberType ScriptMethod -Name "originId" -Value {
			switch ($this.resourceType) { # Resolve originId (eg. get the ObjectId of a group resource)
				"AadGroup" {
					 $originId = Resolve-Group -InputReference $this.resourceIdentifier -DontFailIfNotExisting
				}
				default {
					$originId = $this.resourceIdentifier
				}
			}
			$originId
		}
		Add-Member -InputObject $object -MemberType ScriptMethod -Name "roleOriginId" -Value { $originId = $this.originId(); if ($originId) { "{0}_{1}" -f $this.resourceRole, $originId }}
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
