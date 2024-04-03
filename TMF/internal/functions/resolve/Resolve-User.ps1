function Resolve-User
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
				$user = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users/{0}" -f $InputReference)).Id
			}
			elseif ($InputReference -match $script:upnRegex) {
				$user = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users?`$filter=userPrincipalName eq '{0}'" -f $InputReference)).Value.Id
			}
			elseif ($InputReference -in @("None", "All", "GuestsOrExternalUsers")) {
				return $InputReference
			}
			else {
				$user = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $user -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["users"].displayName) {
					$user = $InputReference
				}
			}
			
			if (-Not $user -and -Not $DontFailIfNotExisting) { throw "Cannot find user $InputReference" } 
			elseif (-Not $user -and $DontFailIfNotExisting) { return }

			if ($user.count -gt 1) { throw "Got multiple users for $InputReference" }
			return $user
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "User" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
