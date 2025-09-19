function Resolve-DirectoryRoleTemplate {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

	begin {
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			# Ensure cache loaded once
			if (-not $script:cache["allRoleTemplates"]) {
				$script:cache["allRoleTemplates"] = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directoryRoleTemplates").Value `
				| Select-Object @{n = "id"; e = { $_["id"] } }, @{n = "displayName"; e = { $_["displayName"] } }
			}
			$results = @()
			foreach ($ref in $InputReference) {
				try {
					if ($ref -match $script:guidRegex) {
						$roleTemplate = $script:cache["allRoleTemplates"] | Where-Object { $_.id -eq $ref } | Select-Object -First 1
					} else {
						$roleTemplate = $script:cache["allRoleTemplates"] | Where-Object { $_.displayName -eq $ref } | Select-Object -First 1
					}
					if (-not $roleTemplate) {
						Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleTemplate resource for input '{0}'. Searched tenant & desired configuration." -f $ref) -Tag failed; $results += $ref; continue
					}
					if ($Expand) {
						$results += [pscustomobject]@{ id = $roleTemplate.id; displayName = $roleTemplate.displayName }
					} elseif ($DisplayName) {
						$results += ($roleTemplate.displayName ?? $ref)
					} else {
						$results += $roleTemplate.id
					}
				} catch {
					Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleTemplate resource for input '{0}'. Error: {1}" -f $ref, $_.Exception.Message) -Tag failed -ErrorRecord $_; $results += $ref
				}
			}
			return , $results
		}
		try {
			if (-not $script:cache["allRoleTemplates"]) {
				$script:cache["allRoleTemplates"] = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directoryRoleTemplates").Value `
				| Select-Object @{n = "id"; e = { $_["id"] } }, @{n = "displayName"; e = { $_["displayName"] } }
			}

			if ($InputReference -match $script:guidRegex) {
				$roleTemplate = $script:cache["allRoleTemplates"] | Where-Object { $_.id -eq $InputReference } | Select-Object -ExpandProperty Id
			} else {
				$roleTemplate = $script:cache["allRoleTemplates"] | Where-Object { $_.displayName -eq $InputReference } | Select-Object -ExpandProperty Id
			}

			if (-not $roleTemplate -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["roleTemplates"].displayName) {
					$roleTemplate = $InputReference
				}
			}

			if (-not $roleTemplate -and -not $DontFailIfNotExisting) {
				throw "Cannot find directoryRoleTemplate $InputReference."
			} elseif (-not $roleTemplate -and $DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleTemplate resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag 'failed'; return $InputReference
			}

			if ($roleTemplate.count -gt 1) {
				throw "Got multiple directoryRoleTemplates for $InputReference"
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return ($script:cache["allRoleTemplates"] | Where-Object { $_.id -eq $roleTemplate } | Select-Object -ExpandProperty displayName)
				} return $roleTemplate
			}
			$detail = $script:cache['allRoleTemplates'] | Where-Object { $_.id -eq $roleTemplate } | Select-Object -First 1
			return [pscustomobject]@{ id = $roleTemplate; displayName = $detail.displayName }
		} catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRoleTemplate resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
		}
	}
}
