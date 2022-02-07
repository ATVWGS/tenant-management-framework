﻿function Resolve-User
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
				$user = Get-MgUser -UserId $InputReference
			}
			elseif ($InputReference -match $script:upnRegex) {
				$user = Get-MgUser -Filter "userPrincipalName eq '$InputReference'"
			}
			elseif ($InputReference -in @("None", "All", "GuestsOrExternalUsers")) {
				return $InputReference
			}
			else {
				$user = Get-MgUser -Filter "displayName eq '$InputReference'"
			}

			if (-Not $user -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["users"].displayName) {
					$user = [ResolvePromise] @{InputReference = $InputReference; ResolveFunction = $MyInvocation.MyCommand}
				}
			}
			
			if (-Not $user -and -Not $DontFailIfNotExisting) { throw "Cannot find user $InputReference" } 
			elseif (-Not $user -and $DontFailIfNotExisting) { return }

			if ($user.count -gt 1) { throw "Got multiple users for $InputReference" }
			return $user.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "User" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
