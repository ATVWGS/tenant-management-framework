function Resolve-DirectoryRoleTemplate
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
			if (-Not $script:cache["allRoleTemplates"]) {
				$script:cache["allRoleTemplates"] = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directoryRoleTemplates").Value `
											| Select-Object @{n = "id"; e = {$_["id"]}}, @{n = "displayName"; e = {$_["displayName"]}}
			}
			
			if ($InputReference -match $script:guidRegex) {
				$roleTemplate = $script:cache["allRoleTemplates"] | Where-Object {$_.id -eq $InputReference} | Select-Object -ExpandProperty Id
			}
			else {
				$roleTemplate = $script:cache["allRoleTemplates"] | Where-Object {$_.displayName -eq $InputReference} | Select-Object -ExpandProperty Id
			}

			if (-Not $roleTemplate -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["roleTemplates"].displayName) {
					$roleTemplate = $InputReference
				}
			}

			if (-Not $roleTemplate -and -Not $DontFailIfNotExisting) { throw "Cannot find directoryRoleTemplate $InputReference." } 
			elseif (-Not $roleTemplate -and $DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleTemplate resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag 'failed'; return $InputReference }

			if ($roleTemplate.count -gt 1) { throw "Got multiple directoryRoleTemplates for $InputReference" }
			if (-not $Expand) { if ($DisplayName) { return ($script:cache["allRoleTemplates"] | Where-Object { $_.id -eq $roleTemplate } | Select-Object -ExpandProperty displayName) } return $roleTemplate }
			$detail = $script:cache['allRoleTemplates'] | Where-Object { $_.id -eq $roleTemplate } | Select-Object -First 1
			return [pscustomobject]@{ id=$roleTemplate; displayName=$detail.displayName }
		}
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleTemplate resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
