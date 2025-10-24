function Resolve-Group {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand,
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
	)
	begin {
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
		if (-not $script:groupDetailCache) {
			$script:groupDetailCache = @{}
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			if (Test-TmfInputsCached -CacheName 'groupDetailCache' -Inputs $InputReference -SkipValues @('All')) {
				$results = foreach ($i in $InputReference) {
					if ($i -eq 'All') {
						'All'
					} elseif ($script:groupDetailCache.ContainsKey($i)) {
						if ($Expand) {
							$script:groupDetailCache[$i]
						} elseif ($DisplayName) {
							$script:groupDetailCache[$i].displayName
						} else {
							$script:groupDetailCache[$i].id
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
				# 1. GUID inputs
				$guidIds = $all | Where-Object { $_ -match $script:guidRegex }
				if ($guidIds.Count -gt 0) {
					if ($DisplayName) {
						try {
							$objs = Resolve-DirectoryObject -InputReference ($guidIds | Where-Object { -not $script:groupDetailCache.ContainsKey($_) }) -Types group -ReturnObjects -DontFailIfNotExisting
							foreach ($g in $objs) {
								if ($g -and $g.id) {
									$detail = [pscustomobject]@{ id = $g.id; displayName = $g.displayName; mailNickname = $g.mailNickname }
									foreach ($k in @($detail.id, $detail.displayName, $detail.mailNickname)) {
										if ($k -and -not $script:groupDetailCache.ContainsKey($k)) {
											$script:groupDetailCache[$k] = $detail
										}
									}
								}
							}
						} catch {
							Write-PSFMessage -Level Verbose -Message ("Resolve-DirectoryObject bulk failed for groups: {0}" -f $_.Exception.Message) -Tag 'prefetch', 'group' -ErrorRecord $_
						}
					} else {
						foreach ($gid in $guidIds | Where-Object { -not $script:groupDetailCache.ContainsKey($_) }) {
							$rid++; $reqId = "g$rid"; $requests += @{ id = $reqId; method = 'GET'; url = "/groups/$gid?`$select=id,displayName,mailNickname" }; $idMap[$reqId] = $gid
						}
					}
				}
				# 2. Non-GUID inputs (displayName or mailNickname)
				$toResolve = $all | Where-Object { -not $script:groupDetailCache.ContainsKey($_) -and ($_ -notmatch $script:guidRegex) }
				foreach ($dn in $toResolve) {
					$rid++; $reqId = "d$rid"
					$escaped = $dn -replace "'", "''"
					# choose filter type by pattern
					if ($dn -match $script:mailNicknameRegex) {
						$requests += @{ id = $reqId; method = 'GET'; url = "/groups?`$filter=mailNickname eq '$escaped'&`$select=id,displayName,mailNickname" }
					} else {
						$requests += @{ id = $reqId; method = 'GET'; url = "/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName,mailNickname" }
					}
					$idMap[$reqId] = $dn
				}
				# Submit in chunks
				for ($i = 0; $i -lt $requests.Count; $i += 20) {
					$chunk = $requests[$i..([Math]::Min($i + 19, $requests.Count - 1))]
					try {
						$body = @{ requests = $chunk } | ConvertTo-Json -Depth 6
						# Escape $ in $batch to call proper Graph batch endpoint
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
										$detail = [pscustomobject]@{ id = $match.id; displayName = $match.displayName; mailNickname = $match.mailNickname }; Add-TmfCacheEntries -CacheName 'groupDetailCache' -Objects @($detail) -KeyProperties id, displayName, mailNickname
									}
								}
							}
						}
					} catch {
						Write-PSFMessage -Level Warning -Message ("Group batch prefetch failed chunk starting index {0}: {1}" -f $i, $_.Exception.Message) -Tag 'batch', 'failed' -ErrorRecord $_
					}
				}
			}
			$single = {
				param($one)
				if ($script:groupDetailCache.ContainsKey($one)) {
					if ($Expand) {
						return $script:groupDetailCache[$one]
					} elseif ($DisplayName) {
						return ($script:groupDetailCache[$one].displayName ?? $one)
					} else {
						return $script:groupDetailCache[$one].id
					}
				}
				return (Resolve-Group -InputReference $one -DontFailIfNotExisting -Expand:$Expand -DisplayName:$DisplayName -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet)
			}
			return Invoke-TmfArrayResolution -Inputs $InputReference -Prefetch $prefetch -ResolveSingle $single
		}
		try {
			if (-not $Expand -and -not $DisplayName -and $script:groupDetailCache.ContainsKey($InputReference)) {
				return $script:groupDetailCache[$InputReference].id
			}
			if (-not $Expand -and $DisplayName -and $script:groupDetailCache.ContainsKey($InputReference)) {
				return ($script:groupDetailCache[$InputReference].displayName ?? $InputReference)
			}
			if ($InputReference -eq 'All') {
				if ($Expand) {
					return [pscustomobject]@{ id = 'All'; displayName = 'All'; mailNickname = 'All' }
				} return 'All'
			}
			$fullObj = $null; $resolvedId = $null
			if ($InputReference -match $script:guidRegex) {
				if ($script:groupDetailCache.ContainsKey($InputReference)) {
					if ($Expand) {
						return $script:groupDetailCache[$InputReference]
					} elseif ($DisplayName) {
						return ($script:groupDetailCache[$InputReference].displayName ?? $InputReference)
					} else {
						return $script:groupDetailCache[$InputReference].id
					}
				}
				$fullObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}?`$select=id,displayName,mailNickname" -f $InputReference)
				$resolvedId = $fullObj.id
			} elseif ($InputReference -match $script:mailNicknameRegex) {
				$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=mailNickname eq '{0}'&`$select=id,displayName,mailNickname" -f $InputReference)).value | Select-Object -First 1
				$resolvedId = $fullObj.id
			} else {
				$InputReference = $InputReference -replace "'","''"
				if ($InputReference -notmatch "'") {
					$InputReference = [System.Web.HttpUtility]::UrlEncode($InputReference)
				}
				$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=displayName eq '{0}'&`$select=id,displayName,mailNickname" -f $InputReference)).value | Select-Object -First 1
				$resolvedId = $fullObj.id
			}
			# Undo Url encoding for returns
			$InputReference = [System.Web.HttpUtility]::UrlDecode($InputReference)
			if (-not $resolvedId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['groups'].displayName) {
					$resolvedId = $InputReference
				}
			}
			if (-not $resolvedId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find group $InputReference"
				}
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return ($fullObj.displayName ?? $InputReference)
				}; return $resolvedId
			}
			$detail = [pscustomobject]@{ id = $resolvedId; displayName = $fullObj.displayName; mailNickname = $fullObj.mailNickname }
			foreach ($k in @($detail.id, $detail.displayName, $detail.mailNickname)) {
				if ($k -and -not $script:groupDetailCache.ContainsKey($k)) {
					$script:groupDetailCache[$k] = $detail
				}
			}
			return $detail
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Group resource for input '{0}'. Error: {1}" -f ($InputReference -join ","), $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Group resource for input '{0}'. Error: {1}" -f ($InputReference -join ","), $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
