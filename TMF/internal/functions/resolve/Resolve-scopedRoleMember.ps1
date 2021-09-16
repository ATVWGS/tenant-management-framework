function Resolve-scopedRoleMember
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
		$InputReference = Resolve-String -Text $InputReference;
	}
	process
	{			
		try {
			if ($InputReference -match $script:guidRegex) {
                if (!(Get-MgUser -UserId $InputReference)){
                    $scopedRoleMember = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}" -f $InputReference)).Value;
                }
                else {
				    $scopedRoleMember = Get-MgUser -UserId $InputReference;
                }
			}
			elseif ($InputReference -match $script:upnRegex) {
                if (!(Get-MgUser -Filter "userPrincipalName eq '$InputReference'")){
                    $scopedRoleMember = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=mailNickname eq '{0}'" -f $InputReference)).Value;
                }
                else {
				    $scopedRoleMember = Get-MgUser -Filter "userPrincipalName eq '$InputReference'";
                }
			}
			elseif ($InputReference -in @("None", "All", "GuestsOrExternalUsers")) {
				return $InputReference;
			}
			else {
                if (!(Get-MgUser -Filter "displayName eq '$InputReference'")){
                    $scopedRoleMember = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=displayName eq '{0}'" -f $InputReference)).Value;
                }
                else{
				    $scopedRoleMember = Get-MgUser -Filter "displayName eq '$InputReference'";
                }
			}
			
			if (-Not $scopedRoleMember -and -Not $DontFailIfNotExisting) { throw "Cannot find user $InputReference"; } 
			elseif (-Not $scopedRoleMember -and $DontFailIfNotExisting) { return }

			if ($scopedRoleMember.count -gt 1) { throw "Got multiple users for $InputReference"; }
			return $scopedRoleMember.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "User" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
		}			
	}
}