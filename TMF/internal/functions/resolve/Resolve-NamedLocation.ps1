function Resolve-NamedLocation {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string[]]$InputReference,
		[switch]$DontFailIfNotExisting,
		[switch]$SearchInDesiredConfiguration,
		[switch]$Expand, # Return object { id, displayName }
		[switch]$DisplayName,
		[System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
	)
	begin {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
		if (-not $script:namedLocationDetailCache) {
			$script:namedLocationDetailCache = @{}
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			if (Test-TmfInputsCached -CacheName 'namedLocationDetailCache' -Inputs $InputReference -SkipValues @('All', 'AllTrusted', 'None')) {
				$results = foreach ($i in $InputReference) {
					if ($i -in @('All', 'AllTrusted', 'None')) {
						$i
					} elseif ($script:namedLocationDetailCache.ContainsKey($i)) {
						if ($Expand) {
							$script:namedLocationDetailCache[$i]
						} elseif ($DisplayName) {
							$script:namedLocationDetailCache[$i].displayName
						} else {
							$script:namedLocationDetailCache[$i].id
						}
					} else {
						$i
					}
				}
				return , $results
			}
			$prefetch = {
				param($all)
				# No bulk endpoint; perform targeted GET for GUIDs only (skip if cached)
				$guidIds = $all | Where-Object { $_ -match $script:guidRegex }
				foreach ($gid in $guidIds) {
					if ($script:namedLocationDetailCache.ContainsKey($gid)) {
						continue
					}
					try {
						$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations/{0}?`$select=id,displayName" -f $gid)
						if ($detail) {
							$obj = [pscustomobject]@{ id = $detail.id; displayName = $detail.displayName }
							Add-TmfCacheEntries -CacheName 'namedLocationDetailCache' -Objects @($obj) -KeyProperties id, displayName
						}
					} catch {
						Write-PSFMessage -Level Verbose -Message ("Prefetch named location guid {0} failed: {1}" -f $gid, $_.Exception.Message) -Tag 'prefetch', 'namedLocation'
					}
				}
			}
			$single = {
				param($one)
				if ($one -ceq "All" -or $one -ceq "AllTrusted" -or $one -ceq "None") {
					return $one
				}
				if ($script:namedLocationDetailCache.ContainsKey($one)) {
					if ($Expand) {
						return $script:namedLocationDetailCache[$one]
					} elseif ($DisplayName) {
						return ($script:namedLocationDetailCache[$one].displayName)
					} else {
						return $script:namedLocationDetailCache[$one].id
					}
				}
				return (Resolve-NamedLocation -InputReference $one -DontFailIfNotExisting -Expand:$Expand -DisplayName:$DisplayName -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet)
			}
			return Invoke-TmfArrayResolution -Inputs $InputReference -Prefetch $prefetch -ResolveSingle $single
		}
		try {
			if ($InputReference -ceq "All") {
				return $InputReference
			}
			if ($InputReference -ceq "AllTrusted") {
				return $InputReference
			}
			if ($InputReference -ceq "None") {
				return $InputReference
			}
			if ($Expand -and $script:namedLocationDetailCache.ContainsKey($InputReference)) {
				return $script:namedLocationDetailCache[$InputReference]
			}
			if (-not $Expand -and -not $DisplayName -and $script:namedLocationDetailCache.ContainsKey($InputReference)) {
				return $script:namedLocationDetailCache[$InputReference].id
			}
			if (-not $Expand -and $DisplayName -and $script:namedLocationDetailCache.ContainsKey($InputReference)) {
				return ($script:namedLocationDetailCache[$InputReference].displayName)
			}
			$nlId = $null; $detail = $null
			if ($InputReference -match $script:guidRegex) {
				try {
					$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations/{0}?`$select=id,displayName" -f $InputReference)
				} catch {
					$detail = $null
				}; if ($detail) {
					$nlId = $detail.id
				}
			} else {
				try {
					$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations?`$filter=displayName eq '{0}'&`$select=id,displayName" -f ($InputReference -replace "'", "''"))).value | Select-Object -First 1; if (-not $detail) {
						$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations?`$select=id,displayName")).value | Where-Object { $_.displayName -eq $InputReference } | Select-Object -First 1
					}
				} catch {
					try {
						$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations?`$select=id,displayName")).value | Where-Object { $_.displayName -eq $InputReference } | Select-Object -First 1
					} catch {
						$detail = $null
					}
				}; if ($detail) {
					$nlId = $detail.id
				}
			}
			if (-not $nlId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['namedLocations'].displayName) {
					$nlId = $InputReference
				}
			}
			if (-not $nlId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find namedLocation $InputReference"
				}
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return ($detail.displayName)
				}
				return $nlId
			}
			if (-not $detail) {
				$detail = [pscustomobject]@{ id = $nlId; displayName = $null }
			}
			$obj = [pscustomobject]@{ id = $detail.id; displayName = $detail.displayName }
			foreach ($key in @($obj.id, $obj.displayName)) {
				if ($key -and -not $script:namedLocationDetailCache.ContainsKey($key)) {
					$script:namedLocationDetailCache[$key] = $obj
				}
			}
			return $obj
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve NamedLocation resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve NamedLocation resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
