function Resolve-ServicePrincipal {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)][string[]]$InputReference,
		[switch]$DontFailIfNotExisting,
		[switch]$SearchInDesiredConfiguration,
		[switch]$Expand, # Return object { id, displayName, appId }
		[switch]$DisplayName,
		[System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
	)
	begin {
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
		if (-not $script:servicePrincipalDetailCache) {
			$script:servicePrincipalDetailCache = @{}
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			if (Test-TmfInputsCached -CacheName 'servicePrincipalDetailCache' -Inputs $InputReference) {
				$results = foreach ($i in $InputReference) {
					if ($script:servicePrincipalDetailCache.ContainsKey($i)) {
						if ($Expand) {
							$script:servicePrincipalDetailCache[$i]
						} elseif ($DisplayName) {
							$script:servicePrincipalDetailCache[$i].displayName
						} else {
							$script:servicePrincipalDetailCache[$i].id
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
				# GUID inputs -> GET /servicePrincipals/{id}
				$guidIds = $all | Where-Object { $_ -match $script:guidRegex }
				foreach ($gid in ($guidIds | Where-Object { -not $script:servicePrincipalDetailCache.ContainsKey($_) })) {
					$rid++; $reqId = "g$rid"
					$requests += @{ id = $reqId; method = 'GET'; url = "/servicePrincipals/$gid?`$select=id,displayName,appId" }
					$idMap[$reqId] = $gid
				}
				# Non-GUID inputs -> filter by displayName
				$names = $all | Where-Object { $_ -notmatch $script:guidRegex -and -not $script:servicePrincipalDetailCache.ContainsKey($_) }
				foreach ($n in $names) {
					$rid++; $reqId = "d$rid"
					$escaped = $n -replace "'", "''"
					$requests += @{ id = $reqId; method = 'GET'; url = "/servicePrincipals?`$filter=displayName eq '$escaped'&`$select=id,displayName,appId" }
					$idMap[$reqId] = $n
				}
				# Submit in chunks (20)
				for ($j = 0; $j -lt $requests.Count; $j += 20) {
					$chunk = $requests[$j..([Math]::Min($j + 19, $requests.Count - 1))]
					try {
						$body = @{ requests = $chunk } | ConvertTo-Json -Depth 6
						# Escape $ for literal /$batch endpoint
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
										$detail = [pscustomobject]@{ id = $match.id; displayName = $match.displayName; appId = $match.appId }
										Add-TmfCacheEntries -CacheName 'servicePrincipalDetailCache' -Objects @($detail) -KeyProperties id, displayName, appId
									}
								}
							}
						}
					} catch {
						Write-PSFMessage -Level Warning -Message ("ServicePrincipal batch prefetch failed chunk starting index {0}: {1}" -f $j, $_.Exception.Message) -Tag 'batch', 'failed' -ErrorRecord $_
					}
				}
			}
			$single = {
				param($one)
				if ($script:servicePrincipalDetailCache.ContainsKey($one)) {
					if ($Expand) {
						return $script:servicePrincipalDetailCache[$one]
					} elseif ($DisplayName) {
						return ($script:servicePrincipalDetailCache[$one].displayName)
					} else {
						return $script:servicePrincipalDetailCache[$one].id
					}
				}
				return (Resolve-ServicePrincipal -InputReference $one -DontFailIfNotExisting -Expand:$Expand -DisplayName:$DisplayName -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet)
			}
			return Invoke-TmfArrayResolution -Inputs $InputReference -Prefetch $prefetch -ResolveSingle $single
		}
		try {
			if ($Expand -and $script:servicePrincipalDetailCache.ContainsKey($InputReference)) {
				return $script:servicePrincipalDetailCache[$InputReference]
			}
			if (-not $Expand -and -not $DisplayName -and $script:servicePrincipalDetailCache.ContainsKey($InputReference)) {
				return $script:servicePrincipalDetailCache[$InputReference].id
			}
			if (-not $Expand -and $DisplayName -and $script:servicePrincipalDetailCache.ContainsKey($InputReference)) {
				return ($script:servicePrincipalDetailCache[$InputReference].displayName)
			}
			$spId = $null; $detail = $null
			if ($InputReference -match $script:guidRegex) {
				try {
					$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}?`$select=id,displayName,appId" -f $InputReference)
				} catch {
					try {
						$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=appId eq '{0}'&`$select=id,displayName,appId" -f $InputReference)).value | Select-Object -First 1
					}
					catch {
						$detail = $null
					}					
				}; if ($detail) {
					$spId = $detail.id
				}
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=displayName eq '{0}'&`$select=id,displayName,appId" -f $InputReference)).value | Select-Object -First 1
				if ($detail) {
					$spId = $detail.id
				}
			}
			if (-not $spId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['servicePrincipals'].displayName) {
					$spId = $InputReference
				}
			}
			if (-not $spId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find servicePrincipal $InputReference"
				}
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return ($detail.displayName)
				}; return $spId
			}
			if (-not $detail) {
				$detail = [pscustomobject]@{ id = $spId; displayName = $null; appId = $null }
			}
			$obj = [pscustomobject]@{ id = $detail.id; displayName = $detail.displayName; appId = $detail.appId }
			foreach ($k in @($obj.id, $obj.displayName, $obj.appId)) {
				if ($k -and -not $script:servicePrincipalDetailCache.ContainsKey($k)) {
					$script:servicePrincipalDetailCache[$k] = $obj
				}
			}
			return $obj
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve ServicePrincipal resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve ServicePrincipal resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
