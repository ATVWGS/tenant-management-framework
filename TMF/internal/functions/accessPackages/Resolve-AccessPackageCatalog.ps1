function Resolve-AccessPackageCatalog
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $AccessPackageCatalogReference,
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$AccessPackageCatalogReference = Resolve-String -Text $AccessPackageCatalogReference
	}
	process
	{			
		try {
			if ($AccessPackageCatalogReference -match $script:guidRegex) {
				$accessPackageCatalog = Get-MgEntitlementManagementAccessPackageCatalog -AccessPackageCatalogId $AccessPackageCatalogReference
			}
			else {
				$accessPackageCatalog = Get-MgEntitlementManagementAccessPackageCatalog -Filter "displayName eq '$AccessPackageCatalogReference'"
			}
			
			if (!$accessPackageCatalog) { throw "Cannot find user $AccessPackageCatalogReference" }
			if ($accessPackageCatalog.count -gt 1) { throw "Got multiple Access Package Catalogs for $AccessPackageCatalogReference" }
			return $accessPackageCatalog
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageCatalog" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
