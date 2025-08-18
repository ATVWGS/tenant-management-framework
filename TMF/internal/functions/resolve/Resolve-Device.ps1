function Resolve-Device {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $Expand, # Return object { id, displayName, deviceId }
		[switch] $DisplayName, # Return displayName (when not -Expand)
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	begin {
		$InputReference = Resolve-String -Text $InputReference
		if (-not $script:deviceDetailCache) { $script:deviceDetailCache = @{} }
	}
	process {
		try {
			if ($Expand -and $script:deviceDetailCache.ContainsKey($InputReference)) { return $script:deviceDetailCache[$InputReference] }
			$detail = $null; $deviceId = $null
			if ($InputReference -match $script:guidRegex) {
				$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/devices/{0}?`$select=id,displayName,deviceId" -f $InputReference)
				$deviceId = $detail.id
			} else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/devices/?`$filter=displayName eq '{0}'&`$select=id,displayName,deviceId" -f $InputReference)).value | Select-Object -First 1
				$deviceId = $detail.id
			}
			if (-not $deviceId) { if ($DontFailIfNotExisting) { return $InputReference } else { throw "Cannot find device $InputReference" } }
			if (-not $Expand) { if ($DisplayName) { return ($detail.displayName ?? $InputReference) } return $deviceId }
			$obj = [pscustomobject]@{ id=$deviceId; displayName=$detail.displayName; deviceId=$detail.deviceId }
			foreach ($k in @($obj.id,$obj.displayName,$obj.deviceId)) { if ($k -and -not $script:deviceDetailCache.ContainsKey($k)) { $script:deviceDetailCache[$k] = $obj } }
			return $obj
		} catch {
			if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve Device resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve Device resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) }
		}
	}
}
