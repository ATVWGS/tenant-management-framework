function Resolve-AccessPackageCatalog
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
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
				$providedId = $true
				$catalog = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}" -f $InputReference)
			}
			else {
				$catalog = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (-Not $catalog -and -Not $DontFailIfNotExisting){ throw "Cannot find accessPackageCatalog $InputReference" } 
			elseif (-Not $catalog -and $DontFailIfNotExisting) { return }

			if ($catalog.count -gt 1 -and -not $providedId) { throw "Got multiple accessPackageCatalogs for $InputReference" }
			return $catalog.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageCatalog" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
