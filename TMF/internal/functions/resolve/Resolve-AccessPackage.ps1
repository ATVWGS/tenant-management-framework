function Resolve-AccessPackage
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
				$package = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}" -f $InputReference)).Value.Id
=======
				$providedId = $true
				$package = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}" -f $InputReference)
>>>>>>> prepare-release/v1.3
			}
			else {
				$package = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $package -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["accessPackages"].displayName) {
					$package = $InputReference
				}
			}

			if (-Not $package -and -Not $DontFailIfNotExisting){ throw "Cannot find accessPackage $InputReference" }
			elseif (-Not $package -and $DontFailIfNotExisting) { return }

<<<<<<< HEAD
			if ($package.count -gt 1) { throw "Got multiple accessPackages for $InputReference" }
			return $package
=======
			if ($package.count -gt 1 -and -not $providedId) { throw "Got multiple accessPackages for $InputReference" }
			return $package.Id
>>>>>>> prepare-release/v1.3
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackage" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
