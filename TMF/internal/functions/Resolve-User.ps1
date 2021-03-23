function Resolve-User
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $UserReference,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$UserReference = Resolve-String -Text $UserReference
	}
	process
	{			
		try {
			if ($UserReference -match $script:guidRegex) {
				$user = Get-MgUser -UserId $UserReference
			}
			elseif ($UserReference -match $script:upnRegex) {
				$user = Get-MgUser -Filter "userPrincipalName eq '$UserReference'"
			}
			elseif ($UserReference -in @("None", "All", "GuestsOrExternalUsers")) {
				$user = $UserReference
			}
			else {
				$user = Get-MgUser -Filter "displayName eq '$UserReference'"
			}
			
			if (!$user) { throw "Cannot find user $UserReference" }
			if ($user.count -gt 1) { throw "Got multiple users for $UserReference" }
			return $user
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "User" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
