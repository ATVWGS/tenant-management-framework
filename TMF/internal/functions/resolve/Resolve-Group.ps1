function Resolve-Group
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
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}" -f $InputReference)).Value.Id
			}
			elseif ($InputReference -match $script:mailNicknameRegex) {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=mailNickname eq '{0}'" -f $InputReference)).Value.Id
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}
			
			if (-Not $group -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["groups"].displayName) {
					$group = $InputReference
				}
			}

			if (-Not $group -and -Not $DontFailIfNotExisting) { throw "Cannot find group $InputReference" } 
			elseif (-Not $group -and $DontFailIfNotExisting) { return }

			if ($group.count -gt 1) { throw "Got multiple groups for $InputReference" }
			return $group
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Group" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
