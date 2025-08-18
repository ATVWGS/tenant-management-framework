function Resolve-Agreement {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)][string]$InputReference,
		[switch]$DontFailIfNotExisting,
		[switch]$SearchInDesiredConfiguration,
		[switch]$Expand, # Return object { id, displayName }
		[switch]$DisplayName,
		[System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
	)
	begin {
		$InputReference = Resolve-String -Text $InputReference
		if (-not $script:agreementDetailCache) { $script:agreementDetailCache = @{} }
	}
	process {
		try {
			if ($Expand -and $script:agreementDetailCache.ContainsKey($InputReference)) { return $script:agreementDetailCache[$InputReference] }
			if (-not $Expand -and -not $DisplayName -and $script:agreementDetailCache.ContainsKey($InputReference)) { return $script:agreementDetailCache[$InputReference].id }
			if (-not $Expand -and $DisplayName -and $script:agreementDetailCache.ContainsKey($InputReference)) { return ($script:agreementDetailCache[$InputReference].displayName ?? $InputReference) }

			$agreementId = $null; $detail = $null
			if ($InputReference -match $script:guidRegex) {
				try { $detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/{0}?`$select=id,displayName" -f $InputReference) } catch { $detail = $null }
				if ($detail) { $agreementId = $detail.id }
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1
				if ($detail) { $agreementId = $detail.id }
			}
			if (-not $agreementId -and $SearchInDesiredConfiguration) { if ($InputReference -in $script:desiredConfiguration['agreements'].displayName) { $agreementId = $InputReference } }
			if (-not $agreementId) { if ($DontFailIfNotExisting) { return $InputReference } else { throw "Cannot find agreement $InputReference" } }
			if (-not $Expand) { if ($DisplayName) { return ($detail.displayName ?? $InputReference) } return $agreementId }
			if (-not $detail) { $detail = [pscustomobject]@{ id=$agreementId; displayName=$null } }
			$obj = [pscustomobject]@{ id=$detail.id; displayName=$detail.displayName }
			foreach ($key in @($obj.id,$obj.displayName)) { if ($key -and -not $script:agreementDetailCache.ContainsKey($key)) { $script:agreementDetailCache[$key] = $obj } }
			return $obj
		}
		catch {
			if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve Agreement resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve Agreement resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) }
		}
	}
}
