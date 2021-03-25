function Resolve-DirectoryRole
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
				$role = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/{0}" -f $InputReference)).Value
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$role = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (!$role) { throw "Cannot find directoryRole $InputReference. Directory roles must be activated (assigned) once, before the /directoryRoles endpoint returns them." }
			if ($role.count -gt 1) { throw "Got multiple directoryRoles for $InputReference" }
			return $role.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "DirectoryRole" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
