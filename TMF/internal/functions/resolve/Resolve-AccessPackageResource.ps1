function Resolve-AccessPackageResource
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[Parameter(Mandatory = $true)]
		[string] $CatalogId,
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
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}/accessPackageResources?`$filter=originId eq '{1}'" -f $CatalogId, $InputReference)).Value.Id
			}
			else {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}/accessPackageResources?`$filter=displayName eq '{1}'" -f $CatalogId, $InputReference)).Value.Id
			}

			if (-Not $resource -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["accessPackageResources"].displayName) {
					$resource = $InputReference
				}
			}

			if (-Not $resource -and -Not $DontFailIfNotExisting){ throw "Cannot find accessPackageResource $InputReference" } 
			elseif (-Not $resource -and $DontFailIfNotExisting) { return }

			if ($resource.count -gt 1) { throw "Got multiple accessPackageResources for $InputReference" }
			return $resource
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageResource" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}