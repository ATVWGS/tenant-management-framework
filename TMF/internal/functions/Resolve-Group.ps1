function Resolve-Group
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $GroupReference,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$GroupReference = Resolve-String -Text $GroupReference
	}
	process
	{			
		try {
			if ($GroupReference -match $script:guidRegex) {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}" -f $GroupReference)).Value
			}
			elseif ($GroupReference -match $script:mailNicknameRegex) {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=mailNickname eq '{0}'" -f $GroupReference)).Value				
			}
			elseif ($GroupReference -in @("All")) {
				$group = $GroupReference
			}
			else {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=displayName eq '{0}'" -f $GroupReference)).Value
			}

			if (!$group) { throw "Cannot find group $GroupReference" }
			if ($group.count -gt 1) { throw "Got multiple groups for $GroupReference" }
			return $group
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Group" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
