function Resolve-User {
	<#
	.SYNOPSIS
	Resolves one or more users (id / GUID, UPN, displayName, special tokens) with caching and optional object expansion.
	.DESCRIPTION
	Modernized resolver implementing array-based bulk resolution. GUID inputs are centralized through Resolve-DirectoryObject
	(single getByIds batches) instead of per-user GET or $batch requests, reducing round-trips and leveraging shared caches.
	Non-GUID inputs (displayName / UPN) still use filtered /users queries via Graph $batch for efficiency.
	Special tokens supported verbatim: All, None, GuestsOrExternalUsers.
		Behavior:
		- Accepts [string[]] $InputReference; returns ordered array when multiple inputs, scalar when single (backward compatible).
		- -Expand returns detail object { id, displayName, userPrincipalName }.
		- -DisplayName returns only displayName (fast path with DirectoryObject batch for GUID inputs).
		- Caches id, displayName, userPrincipalName under each of those keys for fast subsequent lookups.
	Limitations / Notes:
		- displayName -> id lookup still requires filtered endpoint; /directoryObjects/getByIds cannot perform name search.
		- For GUIDs we always retrieve detail once (even if only id requested) to warm cache for potential later displayName requests.
	# TODO: Add Pester tests (CI-002, CI-005, POW-FUNC-028) covering: (a) GUID bulk path via Resolve-DirectoryObject, (b) non-GUID batch filters, (c) mixed cached + uncached, (d) order preservation, (e) scalar vs array return, (f) DontFailIfNotExisting echo semantics.
	#>

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand,
		[switch] $UserPrincipalName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

	begin {
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
		if (-not $script:userDetailCache) {
			$script:userDetailCache = @{}
		}
	}
	process {
		# Array handling wrapper
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			# Early exit if everything already cached (excluding special values)
			if (Test-TmfInputsCached -CacheName 'userDetailCache' -Inputs $InputReference -SkipValues @('All', 'None', 'GuestsOrExternalUsers')) {
				$results = foreach ($i in $InputReference) {
					if ($i -in @('All', 'None', 'GuestsOrExternalUsers')) {
						$i
					} elseif ($script:userDetailCache.ContainsKey($i)) {
						if ($Expand) {
							$script:userDetailCache[$i]
						} elseif ($UserPrincipalName) {
							$script:userDetailCache[$i].userPrincipalName
						} else {
							$script:userDetailCache[$i].id
						}
					} else {
						$i
					}
				}
				return , $results
			}
			$prefetch = {
				param($all)
				$needDetail = $true # Always fetch detail for GUIDs to warm cache
				# GUID inputs centralized via Resolve-DirectoryObject
				$guidIds = $all | Where-Object { $_ -match $script:guidRegex } | Select-Object -Unique
				if ($guidIds.Count -gt 0) {
					try {
						$resolvedObjs = Resolve-DirectoryObject -InputReference $guidIds -Types user -ReturnObjects -DontFailIfNotExisting
						if ($resolvedObjs) {
							foreach ($obj in $resolvedObjs) {
								if ($obj -is [string]) {
									continue
								} # unresolved echoed
								$detail = [pscustomobject]@{ id = $obj.id; displayName = $obj.displayName; userPrincipalName = $obj.userPrincipalName }
								Add-TmfCacheEntries -CacheName 'userDetailCache' -Objects @($detail) -KeyProperties id, displayName, userPrincipalName
							}
						}
					} catch {
						Write-PSFMessage -Level Verbose -Message ("Resolve-DirectoryObject bulk user prefetch failed: {0}" -f $_.Exception.Message) -Tag 'prefetch', 'user', 'directoryObject' -ErrorRecord $_
					}
				}
				# Non-GUID inputs (displayName / UPN) still use $batch filtered queries
				$requests = @(); $idMap = @{}; $ridCounter = 0
				$toResolve = $all | Where-Object { -not $script:userDetailCache.ContainsKey($_) -and ($_ -notmatch $script:guidRegex) -and ($_ -notin @('All', 'None', 'GuestsOrExternalUsers')) }
				if ($toResolve.Count -gt 0) {
					$displayNames = $toResolve | Where-Object { $_ -notmatch $script:upnRegex }
					$upns = $toResolve | Where-Object { $_ -match $script:upnRegex }
					foreach ($dn in $displayNames) {
						$ridCounter++; $rid = "d$ridCounter"; $escaped = $dn -replace "'", "''"
						$requests += @{ id = $rid; method = 'GET'; url = "/users?`$filter=displayName eq '$escaped'&`$select=id,displayName,userPrincipalName" }
						$idMap[$rid] = $dn
					}
					foreach ($u in $upns) {
						$ridCounter++; $rid = "u$ridCounter"; $escaped = $u -replace "'", "''"
						$requests += @{ id = $rid; method = 'GET'; url = "/users?`$filter=userPrincipalName eq '$escaped'&`$select=id,displayName,userPrincipalName" }
						$idMap[$rid] = $u
					}
				}
				for ($i = 0; $i -lt $requests.Count; $i += 20) {
					$chunk = $requests[$i..([Math]::Min($i + 19, $requests.Count - 1))]
					try {
						$body = @{ requests = $chunk } | ConvertTo-Json -Depth 6
						$response = Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/`$batch") -Body $body -ContentType 'application/json'
						if ($response -and $response.responses) {
							foreach ($r in $response.responses) {
								if ($r.status -ge 200 -and $r.status -lt 300 -and $r.body) {
									$origInput = if ($idMap.ContainsKey($r.id)) {
										$idMap[$r.id]
									} else {
										$null
									}
									$match = if ($r.body.value) {
										$r.body.value | Select-Object -First 1
									} else {
										$r.body
									}
									if ($match) {
										$detail = [pscustomobject]@{ id = $match.id; displayName = $match.displayName; userPrincipalName = $match.userPrincipalName }
										Add-TmfCacheEntries -CacheName 'userDetailCache' -Objects @($detail) -KeyProperties id, displayName, userPrincipalName
										if ($origInput -and -not $script:userDetailCache.ContainsKey($origInput)) {
											$script:userDetailCache[$origInput] = $detail
										}
									}
								}
							}
						}
					} catch {
						Write-PSFMessage -Level Warning -Message ("User batch prefetch failed chunk starting index {0}: {1}" -f $i, $_.Exception.Message) -Tag 'batch', 'failed' -ErrorRecord $_
					}
				}
			}
			$single = {
				param($one)
				if ($script:userDetailCache.ContainsKey($one)) {
					if ($Expand) {
						return $script:userDetailCache[$one]
					} elseif ($UserPrincipalName) {
						return ($script:userDetailCache[$one].userPrincipalName ?? $one)
					} else {
						return $script:userDetailCache[$one].id
					}
				}
				return (Resolve-User -InputReference $one -DontFailIfNotExisting -Expand:$Expand -UserPrincipalName:$UserPrincipalName -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet)
			}
			return Invoke-TmfArrayResolution -Inputs $InputReference -Prefetch $prefetch -ResolveSingle $single
		}
		try {
			# Fast path cache checks
			if (-not $Expand -and -not $UserPrincipalName -and $script:userDetailCache.ContainsKey($InputReference)) {
				return $script:userDetailCache[$InputReference].id
			}
			if (-not $Expand -and $UserPrincipalName -and $script:userDetailCache.ContainsKey($InputReference)) {
				return ($script:userDetailCache[$InputReference].userPrincipalName ?? $InputReference)
			}
			if ($InputReference -in @('None', 'All', 'GuestsOrExternalUsers')) {
				if ($Expand) {
					return [pscustomobject]@{ id = $InputReference; displayName = $InputReference; userPrincipalName = $InputReference }
				} return $InputReference
			}

			$fullObj = $null; $resolvedId = $null; $needDetail = $Expand -or $UserPrincipalName
			if ($InputReference -match $script:guidRegex) {
				if ($script:userDetailCache.ContainsKey($InputReference)) {
					if ($Expand) {
						return $script:userDetailCache[$InputReference]
					} elseif ($UserPrincipalName) {
						return ($script:userDetailCache[$InputReference].userPrincipalName ?? $InputReference)
					} else {
						return $script:userDetailCache[$InputReference].id
					}
				}
				try {
					$resolved = Resolve-DirectoryObject -InputReference $InputReference -Types user -ReturnObjects -DontFailIfNotExisting
					if ($resolved -and $resolved -isnot [string]) {
						$fullObj = [pscustomobject]@{ id = $resolved.id; displayName = $resolved.displayName; userPrincipalName = $resolved.userPrincipalName }
						Add-TmfCacheEntries -CacheName 'userDetailCache' -Objects @($fullObj) -KeyProperties id, displayName, userPrincipalName
						$resolvedId = $fullObj.id
					} elseif (-not $resolvedId) {
						if ($DontFailIfNotExisting) {
							return $InputReference
						} else {
							throw "Cannot find user $InputReference"
						}
					}
				} catch {
					if ($DontFailIfNotExisting) {
						Write-PSFMessage -Level Warning -Message ("Cannot resolve User (GUID) '{0}': {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
					} else {
						throw
					}
				}
			} elseif ($InputReference -match $script:upnRegex) {
				try {
					$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users?`$filter=userPrincipalName eq '{0}'&`$select=id,displayName,userPrincipalName" -f $InputReference)).value | Select-Object -First 1; $resolvedId = $fullObj.id
				} catch {
					if ($DontFailIfNotExisting) {
						Write-PSFMessage -Level Warning -Message ("Cannot resolve User (UPN) '{0}': {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
					} else {
						throw
					}
				}
			} else {
				try {
					$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users?`$filter=displayName eq '{0}'&`$select=id,displayName,userPrincipalName" -f $InputReference)).value | Select-Object -First 1; $resolvedId = $fullObj.id
				} catch {
					if ($DontFailIfNotExisting) {
						Write-PSFMessage -Level Warning -Message ("Cannot resolve User (displayName) '{0}': {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
					} else {
						throw
					}
				}
			}
			if (-not $resolvedId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['users'].displayName) {
					$resolvedId = $InputReference
				}
			}
			if (-not $resolvedId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find user $InputReference"
				}
			}
			if (-not $Expand) {
				if ($UserPrincipalName) {
					return ($fullObj.userPrincipalName ?? $InputReference)
				}; return $resolvedId
			}
			if (-not $fullObj) {
				$fullObj = [pscustomobject]@{ id = $resolvedId; displayName = $null; userPrincipalName = $null }
			}
			$detail = [pscustomobject]@{ id = $fullObj.id; displayName = $fullObj.displayName; userPrincipalName = $fullObj.userPrincipalName }
			foreach ($key in @($detail.id, $detail.displayName, $detail.userPrincipalName)) {
				if ($key -and -not $script:userDetailCache.ContainsKey($key)) {
					$script:userDetailCache[$key] = $detail
				}
			}
			return $detail
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve User '{0}': {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve User '{0}': {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
