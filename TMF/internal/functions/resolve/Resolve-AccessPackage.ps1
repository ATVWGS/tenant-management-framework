function Resolve-AccessPackage
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
				$package = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}" -f $InputReference)
			}
			else {
				$package = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (-Not $package -and -Not $DontFailIfNotExisting){ throw "Cannot find accessPackage $InputReference" }
			elseif (-Not $package -and $DontFailIfNotExisting) { return }

			if ($package.count -gt 1 -and -not $providedId) { throw "Got multiple accessPackages for $InputReference" }
			return $package.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackage" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
