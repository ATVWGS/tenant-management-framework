function Resolve-ConnectedOrganization
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
				$catalog = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/connectedOrganizations/{0}" -f $InputReference)).Value
			}
			else {
				$catalog = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/connectedOrganizations/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (!$catalog){ throw "Cannot find connectedOrganization $InputReference" }
			if ($catalog.count -gt 1) { throw "Got multiple connectedOrganizations for $InputReference" }
			return $catalog.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "ConnectedOrganization" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
