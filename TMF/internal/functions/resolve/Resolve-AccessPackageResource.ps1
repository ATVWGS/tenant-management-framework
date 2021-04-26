function Resolve-AccessPackageResource
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[Parameter(Mandatory = $true)]
		[string] $CatalogId,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		try {
			if ($InputReference -match $script:guidRegex) {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}/accessPackageResources?`$filter=originId eq '{1}'" -f $CatalogId, $InputReference)).Value
			}
			else {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}/accessPackageResources?`$filter=displayName eq '{1}'" -f $CatalogId, $InputReference)).Value
			}

			if (!$resource){ throw "Cannot find accessPackageResource $InputReference" }
			if ($resource.count -gt 1) { throw "Got multiple accessPackageResources for $InputReference" }
			return $resource.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageResource" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
