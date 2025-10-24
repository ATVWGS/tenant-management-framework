function Resolve-AccessPackage {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string[]] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	begin {
		if ($InputReference.Count -gt 1) {
			$InputReference = $InputReference | ForEach-Object { Resolve-String -Text $_ }
		} else {
			$InputReference = Resolve-String -Text $InputReference[0]
		}; if (-not $script:accessPackageDetailCache) {
			$script:accessPackageDetailCache = @{}
		}
	}
	process {
		if ($InputReference -is [array] -and $InputReference.Count -gt 1) {
			$results = @()
			foreach ($ref in $InputReference) {
				try {
					$results += Resolve-AccessPackage -InputReference $ref -DontFailIfNotExisting -Expand:$Expand -DisplayName:$DisplayName -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet
				} catch {
					Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackage resource for input '{0}'. Error: {1}" -f $ref, $_.Exception.Message) -Tag failed -ErrorRecord $_; $results += $ref
				}
			}
			return , $results
		}
		try {
			if ($Expand -and $script:accessPackageDetailCache.ContainsKey($InputReference)) {
				return $script:accessPackageDetailCache[$InputReference]
			}
			$detail = $null; $pkgId = $null
			if ($InputReference -match $script:guidRegex) {
				$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/{0}?`$select=id,displayName" -f $InputReference)
				$pkgId = $detail.id
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).value | Select-Object -First 1
				$pkgId = $detail.id
			}
			if (-not $pkgId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['accessPackages'].displayName) {
					$pkgId = $InputReference
				}
			}
			if (-not $pkgId) {
				if ($DontFailIfNotExisting) {
					return $InputReference
				} else {
					throw "Cannot find accessPackage $InputReference"
				}
			}
			if (-not $Expand) {
				if ($DisplayName) {
					return ($detail.displayName ?? $InputReference)
				} return $pkgId
			}
			$obj = [pscustomobject]@{ id = $pkgId; displayName = $detail.displayName }
			foreach ($k in @($obj.id, $obj.displayName)) {
				if ($k -and -not $script:accessPackageDetailCache.ContainsKey($k)) {
					$script:accessPackageDetailCache[$k] = $obj
				}
			}
			return $obj
		} catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackage resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackage resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference, $_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
