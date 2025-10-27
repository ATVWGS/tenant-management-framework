function Resolve-DirectoryRole
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $DisplayName,
		[switch] $Expand, # Return object { id, displayName, roleTemplateId }
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
				$response = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles?`$filter=id eq '{0}'" -f $InputReference)).Value
				if ($DisplayName) {
					$role = $response.displayName	
				}
				elseif ($Expand) {
					$role = [pscustomObject]@{id = $response.id; displayName = $response.displayName; roleTemplateId = $response.roleTemplateId}
				}
				else {
					$role = $response.Id
				}
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$response = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
				if ($DisplayName) {
					$role = $response.displayName
				}
				elseif ($Expand) {
					if ($response) {
						$role = [pscustomObject]@{id = $response.id; displayName = $response.displayName; roleTemplateId = $response.roleTemplateId}
					}
					else {
						$role = $null
					}
				}
				else {
					$role = $response.Id
				}
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