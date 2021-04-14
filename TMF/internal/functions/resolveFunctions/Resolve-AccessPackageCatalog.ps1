function Resolve-AccessPackageCatalog
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
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
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}" -f $InputReference)).Value
			}
			else {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (!$group) { throw "Cannot find accessPackageCatalog $InputReference" }
			if ($group.count -gt 1) { throw "Got multiple accessPackageCatalogs for $InputReference" }
			return $group.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageCatalog" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
