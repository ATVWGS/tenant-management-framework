function Resolve-DirectoryRoleDefinition
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		try {
			$detail = $null; $roleDefinition = $null
			if ($InputReference -match $script:guidRegex) {
				$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/roleManagement/directory/roleDefinitions/{0}?`$select=id,displayName" -f $InputReference)
				$roleDefinition = $detail.id
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/roleManagement/directory/roleDefinitions/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1
				$roleDefinition = $detail.id
			}

			if (-Not $roleDefinition -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["roleDefinitions"].displayName) {
					$roleDefinition = $InputReference
				}
			}

			if (-Not $roleDefinition -and -Not $DontFailIfNotExisting) { throw "Cannot find directoryRole $InputReference." } 
			elseif (-Not $roleDefinition -and $DontFailIfNotExisting) { return }

			if ($roleDefinition.count -gt 1) { throw "Got multiple directory/roleDefinitions for $InputReference" }
			if (-not $Expand) { if ($DisplayName) { return ($detail.displayName) } return $roleDefinition }
			return [pscustomobject]@{ id=$roleDefinition; displayName=$detail.displayName }
		}
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleDefinition resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
