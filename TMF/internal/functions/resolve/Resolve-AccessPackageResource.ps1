function Resolve-AccessPackageResource {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)] [string] $InputReference,
		[Parameter(Mandatory = $true)] [string] $CatalogId,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName, originId }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
	)
	begin { $InputReference = Resolve-String -Text $InputReference; if (-not $script:accessPackageResourceDetailCache) { $script:accessPackageResourceDetailCache = @{} } }
	process { try {
		if ($Expand -and $script:accessPackageResourceDetailCache.ContainsKey($InputReference)) { return $script:accessPackageResourceDetailCache[$InputReference] }
		$detail = $null; $resId = $null; $originId = $null
		$filterField = ($InputReference -match $script:guidRegex) ? 'originId' : 'displayName'
		$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}/accessPackageResources?`$filter=$filterField eq '{1}'" -f $CatalogId,$InputReference)).value | Select-Object -First 1
		if ($detail) { $resId = $detail.id; $originId = $detail.originId }
		if (-not $resId -and $SearchInDesiredConfiguration) {
			$catalogName = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}?`$select=displayName" -f $CatalogId)).displayName
			$dn = "$catalogName - $InputReference"; if ($dn -in $script:desiredConfiguration['accessPackageResources'].displayName) { $resId = $InputReference }
		}
		if (-not $resId) { if ($DontFailIfNotExisting) { return $InputReference } else { throw "Cannot find accessPackageResource $InputReference" } }
		if (-not $Expand) { if ($DisplayName) { return ($detail.displayName ?? $InputReference) } return $resId }
		if (-not $detail -and $resId) { $detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageCatalogs/{0}/accessPackageResources/{1}?`$select=id,displayName,originId" -f $CatalogId,$resId) }
		$obj = [pscustomobject]@{ id=$resId; displayName=$detail.displayName; originId=($detail.originId ?? $originId) }
		foreach ($k in @($obj.id,$obj.displayName,$obj.originId)) { if ($k -and -not $script:accessPackageResourceDetailCache.ContainsKey($k)) { $script:accessPackageResourceDetailCache[$k] = $obj } }
		return $obj
	} catch { if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackageResource resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve AccessPackageResource resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) } } }
}