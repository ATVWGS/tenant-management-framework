function Resolve-AccessPackageCatalog {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	begin {
		$InputReference = Resolve-String -Text $InputReference; if (-not $script:accessPackageCatalogDetailCache) {
			$script:accessPackageCatalogDetailCache = @{}
		}
	}
	process {
		try {
			if ($Expand -and $script:accessPackageCatalogDetailCache.ContainsKey($InputReference)) {
				return $script:accessPackageCatalogDetailCache[$InputReference]
			}
			$detail = $null; $catId = $null
			if ($InputReference -match $script:guidRegex) {
				$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}?`$select=id,displayName" -f $InputReference); $catId = $detail.id
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1; $catId = $detail.id
			}
			if (-not $catId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['accessPackageCatalogs'].displayName) {
					$catId = $InputReference
				}
			}
			if (-not $catId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find accessPackageCatalog $InputReference"
				}
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return $detail.displayName
				} return $catId
			}
			$obj = [pscustomobject]@{ id = $catId; displayName = $detail.displayName }
			foreach ($k in @($obj.id, $obj.displayName)) {
				if ($k -and -not $script:accessPackageCatalogDetailCache.ContainsKey($k)) {
					$script:accessPackageCatalogDetailCache[$k] = $obj
				}
			}
			return $obj
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackageCatalog resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackageCatalog resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
