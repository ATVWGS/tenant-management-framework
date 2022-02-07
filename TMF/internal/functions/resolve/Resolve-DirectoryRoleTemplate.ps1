function Resolve-DirectoryRoleTemplate
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
			elseif (-Not $roleTemplate -and $DontFailIfNotExisting) { return }

			if ($roleTemplate.count -gt 1) { throw "Got multiple directoryRoleTemplates for $InputReference" }
			return $roleTemplate
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "DirectoryRoleTemplate" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
