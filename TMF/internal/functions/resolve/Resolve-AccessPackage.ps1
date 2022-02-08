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
				$package = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}" -f $InputReference)).Value.Id
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

			if ($package.count -gt 1) { throw "Got multiple accessPackages for $InputReference" }
			return $package
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Group" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}
	}	
}
