function Resolve-Application {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # When set return object with appId, servicePrincipalId, applicationObjectId, displayName
		[switch] $ReturnObjectId, # When set (and not Expand) return the application (app registration) object id instead of appId
		[switch] $DisplayName, # Return displayName if not -Expand
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

	begin {
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}
		if (-not $script:applicationDetailCache) {
			$script:applicationDetailCache = @{}
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			if (Test-TmfInputsCached -CacheName 'applicationDetailCache' -Inputs $InputReference -SkipValues @('All', 'Office365', 'MicrosoftAdminPortals')) {
				$results = foreach ($i in $InputReference) {
					if ($i -in @('All', 'Office365', 'MicrosoftAdminPortals')) {
						$i
					} elseif ($script:applicationDetailCache.ContainsKey($i)) {
						$detail = $script:applicationDetailCache[$i]
						if ($Expand) {
							$detail
						} elseif ($DisplayName) {
							$detail.displayName
						} elseif ($ReturnObjectId) {
							($detail.applicationObjectId ?? $detail.servicePrincipalId ?? $detail.appId)
						} else {
							$detail.appId
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
				# GUID-like inputs: could be servicePrincipal id, application object id, or appId
				$guidish = $all | Where-Object { $_ -match $script:guidRegex }
				if ($guidish.Count -gt 0) {
					foreach ($g in $guidish | Where-Object { -not $script:applicationDetailCache.ContainsKey($_) }) {
						$rid++; $reqId = "g$rid"
						$requests += @{ id = $reqId; method = 'GET'; url = "/servicePrincipals/$g?`$select=id,appId,displayName" }
						$requests += @{ id = "$reqId-app"; method = 'GET'; url = "/applications/$g?`$select=id,appId,displayName" }
						$idMap[$reqId] = $g; $idMap["$reqId-app"] = $g
					}
				}
				# Non-GUID inputs (displayName)
				$toResolve = $all | Where-Object { -not $script:applicationDetailCache.ContainsKey($_) -and ($_ -notmatch $script:guidRegex) }
				foreach ($dn in $toResolve) {
					$rid++; $reqId = "d$rid"
					$escaped = $dn -replace "'", "''"
					$requests += @{ id = "$reqId-appdn"; method = 'GET'; url = "/applications?`$filter=displayName eq '$escaped'&`$select=id,appId,displayName" }
					$requests += @{ id = "$reqId-spdn"; method = 'GET'; url = "/servicePrincipals?`$filter=(displayName eq '$escaped') and (servicePrincipalType eq 'Application')&`$select=id,appId,displayName" }
					$idMap["$reqId-appdn"] = $dn; $idMap["$reqId-spdn"] = $dn
				}
				# Submit in chunks
				for ($i = 0; $i -lt $requests.Count; $i += 20) {
					$chunk = $requests[$i..([Math]::Min($i + 19, $requests.Count - 1))]
					try {
						$body = @{ requests = $chunk } | ConvertTo-Json -Depth 6
						# Fix: literal $batch endpoint required
						$response = Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/`$batch") -Body $body -ContentType 'application/json'
						if ($response -and $response.responses) {
							foreach ($r in $response.responses) {
								if ($r.status -ge 200 -and $r.status -lt 300 -and $r.body) {
									# normalize match
									$match = $null
									if ($r.body.value) {
										$match = $r.body.value | Select-Object -First 1
									} else {
										$match = $r.body
									}
									if ($match) {
										$servicePrincipalId = $null; $applicationObjectId = $null
										if ($r.id -like '*-sp*' -or $r.id -like 'g*') {
											$servicePrincipalId = $match.id
										}
										if ($r.id -like '*-app*' -or $r.id -like '*appdn') {
											$applicationObjectId = $match.id
										}
										$detail = [pscustomobject]@{ appId = $match.appId; servicePrincipalId = $servicePrincipalId; applicationObjectId = $applicationObjectId; displayName = $match.displayName }
										Add-TmfCacheEntries -CacheName 'applicationDetailCache' -Objects @($detail) -KeyProperties appId, servicePrincipalId, applicationObjectId, displayName
									}
								}
							}
						}
					} catch {
						Write-PSFMessage -Level Warning -Message ("Application batch prefetch failed chunk starting index {0}: {1}" -f $i, $_.Exception.Message) -Tag 'batch', 'failed' -ErrorRecord $_
					}
				}
			}
			$single = {
				param($one)
				if ($script:applicationDetailCache.ContainsKey($one)) {
					$detail = $script:applicationDetailCache[$one]
					if ($Expand) {
						return $detail
					} elseif ($DisplayName) {
						return ($detail.displayName ?? $one)
					} elseif ($ReturnObjectId) {
						return ($detail.applicationObjectId ?? $detail.servicePrincipalId ?? $detail.appId)
					} else {
						return $detail.appId
					}
				}
				return (Resolve-Application -InputReference $one -DontFailIfNotExisting -Expand:$Expand -DisplayName:$DisplayName -ReturnObjectId:$ReturnObjectId -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet)
			}
			return Invoke-TmfArrayResolution -Inputs $InputReference -Prefetch $prefetch -ResolveSingle $single
		}
		try {
			# Keywords / special tokens
			if ($InputReference -in @('All', 'Office365', 'MicrosoftAdminPortals')) {
				if ($Expand) {
					return [pscustomobject]@{ appId = $InputReference; id = $InputReference; displayName = $InputReference }
				}
				return $InputReference
			}

			# If cache contains either SP object id or appId, return quickly on -Expand
			if ($script:applicationDetailCache.ContainsKey($InputReference)) {
				if ($Expand) {
					return $script:applicationDetailCache[$InputReference]
				} else {
					if ($DisplayName) {
						return ($script:applicationDetailCache[$InputReference].displayName ?? $InputReference)
					}; if ($ReturnObjectId) {
						return ($script:applicationDetailCache[$InputReference].applicationObjectId ?? $script:applicationDetailCache[$InputReference].servicePrincipalId ?? $script:applicationDetailCache[$InputReference].appId)
					}; return $script:applicationDetailCache[$InputReference].appId
				}
			}

			$appId = $null
			$spObj = $null
			$spId = $null
			$appRegObj = $null
			$appRegId = $null

			if ($InputReference -match $script:guidRegex) {
				# Try application object first (app registration)
				try {
					$appRegObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/{0}?`$select=id,appId,displayName" -f $InputReference) -ErrorAction Stop
				} catch {
					$appRegObj = $null
				}
				if ($appRegObj) {
					$appRegId = $appRegObj.id; $appId = $appRegObj.appId
				}
				# Try service principal object id
				try {
					$spObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}?`$select=id,appId,displayName" -f $InputReference) -ErrorAction Stop
				} catch {
					$spObj = $null
				}
				if ($spObj -and -not $appId) {
					$spId = $spObj.id; $appId = $spObj.appId
				}
				# If still missing, maybe provided value is actually appId (client id)
				if (-not $appId) {
					$spObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
					if ($spObj) {
						$spId = $spObj.id; $appId = $spObj.appId
					}
					if (-not $appRegObj) {
						$appRegObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
					}
					if ($appRegObj) {
						$appRegId = $appRegObj.id; if (-not $appId) {
							$appId = $appRegObj.appId
						}
					}
				}
			} else {
				# Treat as displayName
				$appRegObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=displayName eq '{0}'&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
				if ($appRegObj) {
					$appRegId = $appRegObj.id; $appId = $appRegObj.appId
				}
				$spObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=(displayName eq '{0}') and (servicePrincipalType eq 'Application')&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
				if ($spObj) {
					$spId = $spObj.id; if (-not $appId) {
						$appId = $spObj.appId
					}
				}
			}

			if (-not $appId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['applications'].displayName) {
					$appId = $InputReference
				}
			}

			if (-not $appId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find application $InputReference"
				}
			}

			if (-not $Expand) {
				if ($DisplayName) {
					return (($spObj.displayName ?? $appRegObj.displayName) ?? $InputReference)
				}
				if ($ReturnObjectId) {
					# Prefer application registration object id; fallback to service principal id; else appId
					return ($appRegId ?? $spId ?? $appId)
				}
				return $appId
			}

			if (-not $spObj) {
				$spObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $appId)).value | Select-Object -First 1
				if ($spObj) {
					$spId = $spObj.id
				}
			}
			if (-not $appRegObj -and $appId) {
				$appRegObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $appId)).value | Select-Object -First 1
				if ($appRegObj) {
					$appRegId = $appRegObj.id
				}
			}
			$detail = [pscustomobject]@{ appId = $appId; servicePrincipalId = $spId; applicationObjectId = $appRegId; displayName = ($spObj.displayName ?? $appRegObj.displayName) }
			# Cache by identifiers
			foreach ($key in @($detail.appId, $detail.servicePrincipalId, $detail.applicationObjectId, $detail.displayName)) {
				if ($key -and -not $script:applicationDetailCache.ContainsKey($key)) {
					$script:applicationDetailCache[$key] = $detail
				}
			}
			return $detail
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Application resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_
				return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Application resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_
				$Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
