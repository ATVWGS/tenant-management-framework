function Resolve-User {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object with id, displayName, userPrincipalName
		[switch] $DisplayName, # Return only displayName (no object) if not using -Expand
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	begin {
		$InputReference = Resolve-String -Text $InputReference
		if (-not $script:userDetailCache) { $script:userDetailCache = @{} }
	}
	process {
		try {
			# Fast path: any cached entry (id, displayName, UPN) when not forcing fresh detail
			if (-not $Expand -and -not $DisplayName -and $script:userDetailCache.ContainsKey($InputReference)) { return $script:userDetailCache[$InputReference].id }
			if (-not $Expand -and $DisplayName -and $script:userDetailCache.ContainsKey($InputReference)) { return ($script:userDetailCache[$InputReference].displayName ?? $InputReference) }
			if ($InputReference -in @('None','All','GuestsOrExternalUsers')) {
				if ($Expand) { return [pscustomobject]@{ id=$InputReference; displayName=$InputReference; userPrincipalName=$InputReference } }
				return $InputReference
			}

			$fullObj = $null
			$resolvedId = $null
			$needDetail = $Expand -or $DisplayName

			if ($InputReference -match $script:guidRegex) {
				if ($script:userDetailCache.ContainsKey($InputReference)) { if ($Expand) { return $script:userDetailCache[$InputReference] } else { if ($DisplayName) { return ($script:userDetailCache[$InputReference].displayName ?? $InputReference) }; return $script:userDetailCache[$InputReference].id } }
				try {
					$select = 'id'
					if ($needDetail) { $select = 'id,displayName,userPrincipalName' }
					$fullObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users/{0}?`$select=$select" -f $InputReference)
					$resolvedId = $fullObj.id
				} catch { if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve User resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { throw } }
			}
			elseif ($InputReference -match $script:upnRegex) {
				try {
					$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users?`$filter=userPrincipalName eq '{0}'&`$select=id,displayName,userPrincipalName" -f $InputReference)).value | Select-Object -First 1
					$resolvedId = $fullObj.id
				} catch { if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve User resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { throw } }
			} else {
				try {
					$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/users?`$filter=displayName eq '{0}'&`$select=id,displayName,userPrincipalName" -f $InputReference)).value | Select-Object -First 1
					$resolvedId = $fullObj.id
				} catch { if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve User resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { throw } }
			}

			if (-not $resolvedId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['users'].displayName) { $resolvedId = $InputReference }
			}

			if (-not $resolvedId) {
				if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve User resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag failed; return $InputReference } else { throw "Cannot find user $InputReference" }
			}

			if (-not $Expand) { if ($DisplayName) { return ($fullObj.displayName ?? $InputReference) }; return $resolvedId }

			if (-not $fullObj) { $fullObj = [pscustomobject]@{ id=$resolvedId; displayName=$null; userPrincipalName=$null } }
			$detail = [pscustomobject]@{ id=$fullObj.id; displayName=$fullObj.displayName; userPrincipalName=$fullObj.userPrincipalName }
			foreach ($key in @($detail.id,$detail.displayName,$detail.userPrincipalName)) {
				if ($key -and -not $script:userDetailCache.ContainsKey($key)) { $script:userDetailCache[$key] = $detail }
			}
			return $detail
		}
		catch {
			if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve User resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve User resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) }
		}
	}
}
