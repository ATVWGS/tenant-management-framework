function Resolve-User
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $UserReference,
		[Parameter(Mandatory = $true)]
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
			else {
				throw "User reference $UserReference is no valid GUID or valid userPrincipalName"
			}
			
			if (!$user) {throw "Cannot find user $UserReference"}				
			return $user
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "User" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
