function Resolve-DirectoryRole
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
				$role = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles?`$filter=id eq '{0}'" -f $InputReference)).Value.Id
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$role = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $role -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["directoryRoles"].displayName) {
					$role = $InputReference
				}
			}

			if (-Not $role -and -Not $DontFailIfNotExisting) { throw "Cannot find directoryRole $InputReference. Directory roles must be activated (assigned) once, before the /directoryRoles endpoint returns them." } 
			elseif (-Not $role -and $DontFailIfNotExisting) { return }

			if ($role.count -gt 1) { throw "Got multiple directoryRoles for $InputReference" }
			return $role
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "DirectoryRole" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
