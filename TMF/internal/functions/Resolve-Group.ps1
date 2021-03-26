function Resolve-Group
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
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}" -f $InputReference)).Value
			}
			elseif ($InputReference -match $script:mailNicknameRegex) {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=mailNickname eq '{0}'" -f $InputReference)).Value				
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (!$group) { throw "Cannot find group $InputReference" }
			if ($group.count -gt 1) { throw "Got multiple groups for $InputReference" }
			return $group.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Group" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
