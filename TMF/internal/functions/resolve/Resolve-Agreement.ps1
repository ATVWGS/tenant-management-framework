function Resolve-Agreement {
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
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
		if (-not $script:agreementDetailCache) {
			$script:agreementDetailCache = @{}
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			if (Test-TmfInputsCached -CacheName 'agreementDetailCache' -Inputs $InputReference) {
				$results = foreach ($i in $InputReference) {
					if ($script:agreementDetailCache.ContainsKey($i)) {
						if ($Expand) {
							$script:agreementDetailCache[$i]
						} elseif ($DisplayName) {
							$script:agreementDetailCache[$i].displayName
						} else {
							$script:agreementDetailCache[$i].id
						}
					} else {
						$i
					}
				}
				return , $results
			}
			$prefetch = {
				param($all)
				$requests = @(); $idMap = @{}; $rid = 0
				# GUID inputs -> direct batch GET each id
				$guidIds = $all | Where-Object { $_ -match $script:guidRegex }
				foreach ($gid in ($guidIds | Where-Object { -not $script:agreementDetailCache.ContainsKey($_) })) {
					$rid++; $reqId = "g$rid"
					$requests += @{ id = $reqId; method = 'GET'; url = "/agreements/$gid?`$select=id,displayName" }
					$idMap[$reqId] = $gid
				}
				# Non-GUID inputs -> batch filter by displayName
				$names = $all | Where-Object { $_ -notmatch $script:guidRegex -and -not $script:agreementDetailCache.ContainsKey($_) }
				foreach ($n in $names) {
					$rid++; $reqId = "d$rid"
					$escaped = $n -replace "'", "''"
					$requests += @{ id = $reqId; method = 'GET'; url = "/agreements?`$filter=displayName eq '$escaped'&`$select=id,displayName" }
					$idMap[$reqId] = $n
				}
				# Submit in chunks
				for ($j = 0; $j -lt $requests.Count; $j += 20) {
					$chunk = $requests[$j..([Math]::Min($j + 19, $requests.Count - 1))]
					try {
						$body = @{ requests = $chunk } | ConvertTo-Json -Depth 6
						# Correct batch URL
						$resp = Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/`$batch") -Body $body -ContentType 'application/json'
						if ($resp -and $resp.responses) {
							foreach ($r in $resp.responses) {
								if ($r.status -ge 200 -and $r.status -lt 300 -and $r.body) {
									$match = $null
									if ($r.body.value) {
										$match = $r.body.value | Select-Object -First 1
									} else {
										$match = $r.body
									}
									if ($match) {
										$detail = [pscustomobject]@{ id = $match.id; displayName = $match.displayName }; Add-TmfCacheEntries -CacheName 'agreementDetailCache' -Objects @($detail) -KeyProperties id, displayName
									}
								}
							}
						}
					} catch {
						Write-PSFMessage -Level Warning -Message ("Agreement batch prefetch failed chunk starting index {0}: {1}" -f $j, $_.Exception.Message) -Tag 'batch', 'failed' -ErrorRecord $_
					}
				}
			}
			$single = {
				param($one)
				if ($script:agreementDetailCache.ContainsKey($one)) {
					if ($Expand) {
						return $script:agreementDetailCache[$one]
					} elseif ($DisplayName) {
						return ($script:agreementDetailCache[$one].displayName)
					} else {
						return $script:agreementDetailCache[$one].id
					}
				}
				return (Resolve-Agreement -InputReference $one -DontFailIfNotExisting -Expand:$Expand -DisplayName:$DisplayName -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet)
			}
			return Invoke-TmfArrayResolution -Inputs $InputReference -Prefetch $prefetch -ResolveSingle $single
		}
		try {
			if ($Expand -and $script:agreementDetailCache.ContainsKey($InputReference)) {
				return $script:agreementDetailCache[$InputReference]
			}
			if (-not $Expand -and -not $DisplayName -and $script:agreementDetailCache.ContainsKey($InputReference)) {
				return $script:agreementDetailCache[$InputReference].id
			}
			if (-not $Expand -and $DisplayName -and $script:agreementDetailCache.ContainsKey($InputReference)) {
				return ($script:agreementDetailCache[$InputReference].displayName)
			}
			$agreementId = $null; $detail = $null
			if ($InputReference -match $script:guidRegex) {
				try {
					$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/{0}?`$select=id,displayName" -f $InputReference)
				} catch {
					$detail = $null
				}; if ($detail) {
					$agreementId = $detail.id
				}
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1; if ($detail) {
					$agreementId = $detail.id
				}
			}
			if (-not $agreementId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['agreements'].displayName) {
					$agreementId = $InputReference
				}
			}
			if (-not $agreementId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find agreement $InputReference"
				}
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return $detail.displayName
				}; return $agreementId
			}
			if (-not $detail) {
				$detail = [pscustomobject]@{ id = $agreementId; displayName = $null }
			}
			$obj = [pscustomobject]@{ id = $detail.id; displayName = $detail.displayName }
			foreach ($k in @($obj.id, $obj.displayName)) {
				if ($k -and -not $script:agreementDetailCache.ContainsKey($k)) {
					$script:agreementDetailCache[$k] = $obj
				}
			}
			return $obj
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Agreement resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Agreement resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
