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
				$catalog = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}" -f $InputReference)).Value.Id
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

			if ($catalog.count -gt 1) { throw "Got multiple accessPackageCatalogs for $InputReference" }
			return $catalog
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Group" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}
	}
}
