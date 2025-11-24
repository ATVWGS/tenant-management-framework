function Resolve-DirectoryObject {
	<#
	.SYNOPSIS
	Resolves one or more Azure AD / Entra directory object IDs (GUID inputs) with caching & optional detail retrieval.
	.DESCRIPTION
	Central bulk resolver used by higher-level Resolve-* functions for GUID inputs. Supports array input preserving order.
	Populates two script caches:
		- $script:directoryObjectCache : id -> id (fast existence / id mapping)
		- $script:directoryObjectDetailCache : id -> detail PSCustomObject { id, displayName, mailNickname, userPrincipalName }
	When -ReturnObjects is specified, detail objects are returned (using getByIds first, falling back to single GET).
	Non-GUID inputs are currently not resolved (future enhancement placeholder) and echoed / cause failure depending on -DontFailIfNotExisting.
	Implements chunked POST /directoryObjects/getByIds (<=100 ids per request). Uses provided -Types filter when supplied.
	Limitations:
		- /directoryObjects/getByIds cannot resolve displayName -> id; callers must use resource-specific resolvers for that scenario.
		- Only a subset of properties is cached; expand if future scenarios need more.
	# TODO: Add Pester tests (CI-002, CI-005, POW-FUNC-028) for: (a) array ordering, (b) mixed cached + uncached, (c) ReturnObjects vs ids, (d) DontFailIfNotExisting behavior.
	#>

	[CmdletBinding()] param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)] [string[]] $InputReference,
		[string[]] $Types,
		[switch] $ReturnObjects,
		[switch] $DontFailIfNotExisting,
		[System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
	)

	begin {
		if (-not $script:directoryObjectCache) {
			$script:directoryObjectCache = @{}
		}
		if (-not $script:directoryObjectDetailCache) {
			$script:directoryObjectDetailCache = @{}
		}
		if ($InputReference) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		}
	}
	process {
		if (-not $InputReference) {
			return
		}

		if ($InputReference.Count -gt 1) {
			$original = $InputReference
			$guidInputs = @(); $results = New-Object System.Collections.Generic.List[object]
			foreach ($token in $original) {
				if ($script:directoryObjectCache.ContainsKey($token)) {
					# Already have at least id; supply detail if requested and available
					if ($ReturnObjects -and $script:directoryObjectDetailCache.ContainsKey($token)) {
						$results.Add($script:directoryObjectDetailCache[$token])
					} else {
						$results.Add($script:directoryObjectCache[$token])
					}
				} elseif ($token -match $script:guidRegex) {
					$guidInputs += $token
				} else {
					if ($DontFailIfNotExisting) {
						Write-PSFMessage -Level Warning -Message ("DirectoryObject non-GUID reference '{0}' not resolved (not supported by getByIds)." -f $token) -Tag 'resolve', 'directoryObject', 'nonguid'; $results.Add($token)
					} else {
						$results.Add($token)
					}
				}
			}
			# Fetch uncached GUIDs (detail always fetched if ReturnObjects to satisfy property needs)
			$toFetch = $guidInputs | Where-Object { -not $script:directoryObjectCache.ContainsKey($_) -or ($ReturnObjects -and -not $script:directoryObjectDetailCache.ContainsKey($_)) } | Select-Object -Unique
			for ($i = 0; $i -lt $toFetch.Count; $i += 100) {
				$chunk = $toFetch[$i..([Math]::Min($i + 99, $toFetch.Count - 1))]
				try {
					$body = @{ ids = $chunk }; if ($Types) {
						$body.types = $Types
					}
					$resp = Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/directoryObjects/getByIds") -Body ($body | ConvertTo-Json) -ContentType 'application/json'
					if ($resp.value) {
						foreach ($obj in $resp.value) {
							if (-not $obj.id) {
								continue
							}
							if (-not $script:directoryObjectCache.ContainsKey($obj.id)) {
								$script:directoryObjectCache[$obj.id] = $obj.id
							}
							# Always capture detail object (enables later ReturnObjects without another network call)
							if (-not $script:directoryObjectDetailCache.ContainsKey($obj.id)) {
								$detail = [pscustomobject]@{ id = $obj.id; displayName = $obj.displayName; mailNickname = $obj.mailNickname; userPrincipalName = $obj.userPrincipalName }
								$script:directoryObjectDetailCache[$obj.id] = $detail
							}
						}
					}
				} catch {
					Write-PSFMessage -Level Warning -Message ("Bulk directoryObjects getByIds failed starting {0}: {1}" -f $chunk[0], $_.Exception.Message) -Tag 'bulk', 'directoryObject', 'failed' -ErrorRecord $_
				} finally {
				}
			}
			# Finalize preserving original order
			$final = foreach ($token in $original) {
				if ($script:directoryObjectCache.ContainsKey($token)) {
					if ($ReturnObjects -and $script:directoryObjectDetailCache.ContainsKey($token)) {
						$script:directoryObjectDetailCache[$token]
					} else {
						$script:directoryObjectCache[$token]
					}
				} elseif ($token -match $script:guidRegex) {
					# Fallback single GET (unexpected miss)
					try {
						$idObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryObjects/{0}" -f $token)
						if ($idObj.id) {
							$script:directoryObjectCache[$token] = $idObj.id
							if (-not $script:directoryObjectDetailCache.ContainsKey($idObj.id)) {
								$script:directoryObjectDetailCache[$idObj.id] = [pscustomobject]@{ id = $idObj.id; displayName = $idObj.displayName; mailNickname = $idObj.mailNickname; userPrincipalName = $idObj.userPrincipalName }
							}
							if ($ReturnObjects) {
								$script:directoryObjectDetailCache[$idObj.id]
							} else {
								$idObj.id
							}
						} elseif ($DontFailIfNotExisting) {
							Write-PSFMessage -Level Warning -Message ("Cannot find directoryObject {0}" -f $token) -Tag 'resolve', 'directoryObject', 'missing'; $token
						} else {
							$Cmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]::new("Cannot find directoryObject $token")), 'DirectoryObjectNotFound', [System.Management.Automation.ErrorCategory]::ObjectNotFound, $token))
						}
					} catch {
						if ($DontFailIfNotExisting) {
							Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryObject '{0}': {1}" -f $token, $_.Exception.Message) -Tag 'failed', 'directoryObject' -ErrorRecord $_; $token
						} else {
							$Cmdlet.ThrowTerminatingError($_)
						}
					}
				} else {
					if ($DontFailIfNotExisting) {
						$token
					} else {
						Write-PSFMessage -Level Warning -Message ("Cannot resolve non-GUID DirectoryObject reference '{0}'." -f $token) -Tag 'failed', 'directoryObject'; $Cmdlet.ThrowTerminatingError([System.Exception]::new("Cannot find directoryObject $token"))
					}
				}
			}
			return , $final
		}

		# Single input path
		$single = $InputReference[0]
		if ($script:directoryObjectCache.ContainsKey($single)) {
			if ($ReturnObjects -and $script:directoryObjectDetailCache.ContainsKey($single)) {
				return $script:directoryObjectDetailCache[$single]
			} return $script:directoryObjectCache[$single]
		}
		if ($single -notmatch $script:guidRegex) {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("DirectoryObject non-GUID reference '{0}' not resolved." -f $single) -Tag 'resolve', 'directoryObject', 'nonguid'; return $single
			}
			$Cmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]::new("Cannot find directoryObject $single")), 'DirectoryObjectNotFound', [System.Management.Automation.ErrorCategory]::ObjectNotFound, $single))
		}
		# Single lookup via getByIds to allow future type filtering consistency
		$body = @{ ids = @($single) }
		if ($Types) {
			$body.types = $Types
		}
		$resp1 = $null
		try {
			foreach ($item in $InputReference) {
				Write-PSFMessage -Level Verbose -Message $Item
			}
			
			$resp1 = Invoke-MgGraphRequest -Method POST -Uri ("$script:graphBaseUrl/directoryObjects/getByIds") -Body ($body | ConvertTo-Json) -ContentType 'application/json'
		} catch {
			Write-PSFMessage -Level Warning -Message ("getByIds single lookup failed for '{0}': {1}" -f $single, $_.Exception.Message) -Tag 'failed', 'directoryObject', 'single' -ErrorRecord $_
			if ($DontFailIfNotExisting) {
				return $single
			} else {
				$Cmdlet.ThrowTerminatingError($_)
			}
		}
		$directoryObject = $resp1.value | Select-Object -First 1
		if (-not $directoryObject) {
			if ($DontFailIfNotExisting) {
				return $single
			}
			$Cmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]::new("Cannot find directoryObject $single")), 'DirectoryObjectNotFound', [System.Management.Automation.ErrorCategory]::ObjectNotFound, $single))
		}
		if (-not $script:directoryObjectCache.ContainsKey($directoryObject.id)) {
			$script:directoryObjectCache[$directoryObject.id] = $directoryObject.id
		}
		if (-not $script:directoryObjectDetailCache.ContainsKey($directoryObject.id)) {
			$script:directoryObjectDetailCache[$directoryObject.id] = [pscustomobject]@{ id = $directoryObject.id; displayName = $directoryObject.displayName; mailNickname = $directoryObject.mailNickname; userPrincipalName = $directoryObject.userPrincipalName }
		}
		if ($ReturnObjects) {
			return $script:directoryObjectDetailCache[$directoryObject.id]
		} else {
			return $directoryObject.id
		}
	}
}
