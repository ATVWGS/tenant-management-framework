function Resolve-DirectoryRoleDefinition
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
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		try {
			if ($InputReference -match $script:guidRegex) {
				$roleDefinition = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/roleManagement/directory/roleDefinitions/{0}" -f $InputReference)).Value
			}
			else {
				$roleDefinition = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/roleManagement/directory/roleDefinitions/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (-Not $roleDefinition -and -Not $DontFailIfNotExisting) { throw "Cannot find directoryRole $InputReference." } 
			elseif (-Not $roleDefinition -and $DontFailIfNotExisting) { return }

			if ($roleDefinition.count -gt 1) { throw "Got multiple directory/roleDefinitions for $InputReference" }
			return $roleDefinition.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "DirectoryRoleDefinition" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
