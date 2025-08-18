function Resolve-AdministrativeUnit {
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
		if (-not $script:administrativeUnitDetailCache) { $script:administrativeUnitDetailCache = @{} }
	}
	process {
		try {
			if ($InputReference -eq 'All') { if ($Expand) { return [pscustomobject]@{ id='All'; displayName='All' } } return 'All' }
			if ($Expand -and $script:administrativeUnitDetailCache.ContainsKey($InputReference)) { return $script:administrativeUnitDetailCache[$InputReference] }
			$detail = $null; $auId = $null
			if ($InputReference -match $script:guidRegex) {
				try { $detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}?`$select=id,displayName" -f $InputReference) } catch { $detail=$null }
				$auId = $detail.id
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1
				$auId = $detail.id
			}
			if (-not $auId -and $SearchInDesiredConfiguration) { if ($InputReference -in $script:desiredConfiguration['administrativeUnits'].displayName) { $auId = $InputReference } }
			if (-not $auId) { if ($DontFailIfNotExisting) { return $InputReference } else { throw "Cannot find administrativeUnit $InputReference" } }
			if (-not $Expand) { if ($DisplayName) { return ($detail.displayName ?? $InputReference) } return $auId }
			$obj = [pscustomobject]@{ id=$auId; displayName=$detail.displayName }
			foreach ($k in @($obj.id,$obj.displayName)) { if ($k -and -not $script:administrativeUnitDetailCache.ContainsKey($k)) { $script:administrativeUnitDetailCache[$k] = $obj } }
			return $obj
		} catch { if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve AdministrativeUnit resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve AdministrativeUnit resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) } }
	}
}
