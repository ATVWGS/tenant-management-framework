function Resolve-AccessPackageCatalog
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
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
<<<<<<< HEAD
				$catalog = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}" -f $InputReference)).Value.Id
=======
				$providedId = $true
				$catalog = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}" -f $InputReference)
>>>>>>> prepare-release/v1.3
			}
			else {
				$catalog = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $catalog -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["accessPackageCatalogs"].displayName) {
					$catalog = $InputReference
				}
			}

			if (-Not $catalog -and -Not $DontFailIfNotExisting){ throw "Cannot find accessPackageCatalog $InputReference" } 
			elseif (-Not $catalog -and $DontFailIfNotExisting) { return }

<<<<<<< HEAD
			if ($catalog.count -gt 1) { throw "Got multiple accessPackageCatalogs for $InputReference" }
			return $catalog
=======
			if ($catalog.count -gt 1 -and -not $providedId) { throw "Got multiple accessPackageCatalogs for $InputReference" }
			return $catalog.Id
>>>>>>> prepare-release/v1.3
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageCatalog" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
