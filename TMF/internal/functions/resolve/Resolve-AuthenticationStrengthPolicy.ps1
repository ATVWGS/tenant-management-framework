function Resolve-AuthenticationStrengthPolicy
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
				$authenticationStrengthPolicy = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationStrengthPolicies/{0}" -f $InputReference)).value.id
			}
			else {
				$authenticationStrengthPolicy = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationStrengthPolicies/?`$filter=displayName eq '{0}'" -f $InputReference)).value.id
			}

			if ((-Not $authenticationStrengthPolicy) -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["authenticationStrengthPolicies"].displayName) {
					$authenticationStrengthPolicy = $InputReference
				}
			}

			if ((-Not $authenticationStrengthPolicy) -and (-Not $DontFailIfNotExisting)) { throw "Cannot find authenticationStrengthPolicy $InputReference" } 
			elseif ((-Not $authenticationStrengthPolicy) -and $DontFailIfNotExisting) { return }

			if ($authenticationStrengthPolicy.count -gt 1) { throw "Got multiple authenticationStrengthPolicies for $InputReference" }
            return $authenticationStrengthPolicy
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "authenticationStrengthPolicy" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
