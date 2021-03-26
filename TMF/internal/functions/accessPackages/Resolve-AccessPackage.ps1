function Resolve-AccessPackage
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $AccessPackageReference,
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$AccessPackageReference = Resolve-String -Text $AccessPackageReference
	}
	process
	{			
		try {
			if ($AccessPackageReference -match $script:guidRegex) {
				$accessPackage = Get-MgEntitlementManagementAccessPackage -AccessPackageId $AccessPackageReference
			}
			else {
				$accessPackage = Get-MgEntitlementManagementAccessPackage -Filter "displayName eq '$AccessPackageReference'"
			}
			
			if (!$accessPackage) { throw "Cannot find user $AccessPackageReference" }
			if ($accessPackage.count -gt 1) { throw "Got multiple Access Package Catalogs for $AccessPackageReference" }
			return $accessPackage
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackage" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
