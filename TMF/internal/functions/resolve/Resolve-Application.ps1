function Resolve-Application
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # When set return object with appId, servicePrincipalId, applicationObjectId, displayName
		[switch] $ReturnObjectId, # When set (and not Expand) return the application (app registration) object id instead of appId
		[switch] $DisplayName, # Return displayName if not -Expand
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

	begin {
		$InputReference = Resolve-String -Text $InputReference
		if (-not $script:applicationDetailCache) { $script:applicationDetailCache = @{} }
	}
	process {
		try {
			# Keywords / special tokens
			if ($InputReference -in @('All','Office365','MicrosoftAdminPortals')) {
				if ($Expand) { return [pscustomobject]@{ appId = $InputReference; id = $InputReference; displayName = $InputReference } }
				return $InputReference
			}

			# If cache contains either SP object id or appId, return quickly on -Expand
			if ($script:applicationDetailCache.ContainsKey($InputReference)) { if ($Expand) { return $script:applicationDetailCache[$InputReference] } else { if ($DisplayName) { return ($script:applicationDetailCache[$InputReference].displayName ?? $InputReference) }; if ($ReturnObjectId) { return ($script:applicationDetailCache[$InputReference].applicationObjectId ?? $script:applicationDetailCache[$InputReference].servicePrincipalId ?? $script:applicationDetailCache[$InputReference].appId) }; return $script:applicationDetailCache[$InputReference].appId } }

			$appId = $null
			$spObj = $null
			$spId = $null
			$appRegObj = $null
			$appRegId = $null

			if ($InputReference -match $script:guidRegex) {
				# Try application object first (app registration)
				try { $appRegObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/{0}?`$select=id,appId,displayName" -f $InputReference) -ErrorAction Stop } catch { $appRegObj = $null }
				if ($appRegObj) { $appRegId = $appRegObj.id; $appId = $appRegObj.appId }
				# Try service principal object id
				try { $spObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}?`$select=id,appId,displayName" -f $InputReference) -ErrorAction Stop } catch { $spObj = $null }
				if ($spObj -and -not $appId) { $spId = $spObj.id; $appId = $spObj.appId }
				# If still missing, maybe provided value is actually appId (client id)
				if (-not $appId) {
					$spObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
					if ($spObj) { $spId = $spObj.id; $appId = $spObj.appId }
					if (-not $appRegObj) { $appRegObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1 }
					if ($appRegObj) { $appRegId = $appRegObj.id; if (-not $appId) { $appId = $appRegObj.appId } }
				}
			}
			else {
				# Treat as displayName
				$appRegObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=displayName eq '{0}'&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
				if ($appRegObj) { $appRegId = $appRegObj.id; $appId = $appRegObj.appId }
				$spObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=(displayName eq '{0}') and (servicePrincipalType eq 'Application')&`$select=id,appId,displayName" -f $InputReference)).value | Select-Object -First 1
				if ($spObj) { $spId = $spObj.id; if (-not $appId) { $appId = $spObj.appId } }
			}

			if (-not $appId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['applications'].displayName) { $appId = $InputReference }
			}

			if (-not $appId) {
				if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve Application resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag failed; return $InputReference } else { throw "Cannot find application $InputReference" }
			}

			if (-not $Expand) {
				if ($DisplayName) { return (($spObj.displayName ?? $appRegObj.displayName) ?? $InputReference) }
				if ($ReturnObjectId) {
					# Prefer application registration object id; fallback to service principal id; else appId
					return ($appRegId ?? $spId ?? $appId)
				}
				return $appId
			}

			if (-not $spObj) {
				$spObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $appId)).value | Select-Object -First 1
				if ($spObj) { $spId = $spObj.id }
			}
			if (-not $appRegObj -and $appId) {
				$appRegObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=appId eq '{0}'&`$select=id,appId,displayName" -f $appId)).value | Select-Object -First 1
				if ($appRegObj) { $appRegId = $appRegObj.id }
			}
			$detail = [pscustomobject]@{ appId = $appId; servicePrincipalId = $spId; applicationObjectId = $appRegId; displayName = ($spObj.displayName ?? $appRegObj.displayName) }
			# Cache by identifiers
			foreach ($key in @($detail.appId,$detail.servicePrincipalId,$detail.applicationObjectId,$detail.displayName)) { if ($key -and -not $script:applicationDetailCache.ContainsKey($key)) { $script:applicationDetailCache[$key] = $detail } }
			return $detail
		}
		catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Application resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_
				return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Application resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_
				$Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
