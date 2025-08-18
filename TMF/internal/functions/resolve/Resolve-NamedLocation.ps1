function Resolve-NamedLocation {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)][string]$InputReference,
		[switch]$DontFailIfNotExisting,
		[switch]$SearchInDesiredConfiguration,
		[switch]$Expand, # Return object { id, displayName, type }
		[switch]$DisplayName,
		[System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
	)
	begin {
		$InputReference = Resolve-String -Text $InputReference
		if (-not $script:namedLocationDetailCache) { $script:namedLocationDetailCache = @{} }
	}
	process {
		try {
			if ($InputReference -in @('All','AllTrusted')) { if ($Expand) { return [pscustomobject]@{ id=$InputReference; displayName=$InputReference; type=$null } } return $InputReference }
			if (-not $Expand -and -not $DisplayName -and $script:namedLocationDetailCache.ContainsKey($InputReference)) { return $script:namedLocationDetailCache[$InputReference].id }
			if (-not $Expand -and $DisplayName -and $script:namedLocationDetailCache.ContainsKey($InputReference)) { return ($script:namedLocationDetailCache[$InputReference].displayName ?? $InputReference) }

			if ($Expand -and $script:namedLocationDetailCache.ContainsKey($InputReference)) { return $script:namedLocationDetailCache[$InputReference] }

			$locationId = $null; $detail = $null
			if ($InputReference -match $script:guidRegex) {
				try { $detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations/{0}?`$select=id,displayName,@odata.type" -f $InputReference) } catch { $detail = $null }
				if ($detail) { $locationId = $detail.id }
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations/?`$filter=displayName eq '{0}'&`$select=id,displayName,@odata.type" -f $InputReference)).value | Select-Object -First 1
				if ($detail) { $locationId = $detail.id }
			}

			if (-not $locationId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['namedLocations'].displayName) { $locationId = $InputReference }
			}

			if (-not $locationId) {
				if ($DontFailIfNotExisting) { return $InputReference } else { throw "Cannot find namedLocation $InputReference" }
			}

			if (-not $Expand) { if ($DisplayName) { return ($detail.displayName ?? $InputReference) } return $locationId }

			if (-not $detail) { $detail = [pscustomobject]@{ id=$locationId; displayName=$null; '@odata.type'=$null } }
			$obj = [pscustomobject]@{ id=$detail.id; displayName=$detail.displayName; type=$detail.'@odata.type' }
			foreach ($key in @($obj.id,$obj.displayName)) { if ($key -and -not $script:namedLocationDetailCache.ContainsKey($key)) { $script:namedLocationDetailCache[$key] = $obj } }
			return $obj
		}
		catch {
			if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve NamedLocation resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve NamedLocation resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) }
		}
	}
}
