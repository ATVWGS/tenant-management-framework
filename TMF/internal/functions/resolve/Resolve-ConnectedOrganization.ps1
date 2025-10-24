function Resolve-ConnectedOrganization
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		try {
			$detail = $null; $org = $null
			if ($InputReference -match $script:guidRegex) { $detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/connectedOrganizations/{0}?`$select=id,displayName" -f $InputReference); $org = $detail.id }
			else { $detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/connectedOrganizations/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1; $org = $detail.id }

			if (-Not $org -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["connectedOrganizations"].displayName) {
					$org = $InputReference
				}
			}

			if (-Not $org -and -Not $DontFailIfNotExisting){ throw "Cannot find connectedOrganization $InputReference" } 
			elseif (-Not $org -and $DontFailIfNotExisting) { return }

			if ($org.count -gt 1) { throw "Got multiple connectedOrganizations for $InputReference" }
			if (-not $Expand) { if ($DisplayName) { return ($detail.displayName ?? $InputReference) } return $org }
			return [pscustomobject]@{ id=$org; displayName=$detail.displayName }
		}
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve ConnectedOrganization resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
