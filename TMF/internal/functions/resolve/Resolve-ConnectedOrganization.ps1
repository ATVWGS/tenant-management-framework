function Resolve-ConnectedOrganization
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
				$org = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/connectedOrganizations/{0}" -f $InputReference)).Value.Id
			}
			else {
				$org = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/connectedOrganizations/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $org -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["connectedOrganizations"].displayName) {
					$org = $InputReference
				}
			}

			if (-Not $org -and -Not $DontFailIfNotExisting){ throw "Cannot find connectedOrganization $InputReference" } 
			elseif (-Not $org -and $DontFailIfNotExisting) { return }

			if ($org.count -gt 1) { throw "Got multiple connectedOrganizations for $InputReference" }
			return $org
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "ConnectedOrganization" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
