function Resolve-Group
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # When set return object id, displayName, mailNickname
		[switch] $DisplayName, # Return only displayName if not -Expand
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
		if (-not $script:groupDetailCache) { $script:groupDetailCache = @{} }
	}
	process
	{			
		try {
			# Fast cache hits
			if (-not $Expand -and -not $DisplayName -and $script:groupDetailCache.ContainsKey($InputReference)) { return $script:groupDetailCache[$InputReference].id }
			if (-not $Expand -and $DisplayName -and $script:groupDetailCache.ContainsKey($InputReference)) { return ($script:groupDetailCache[$InputReference].displayName ?? $InputReference) }
			if ($InputReference -eq 'All') { if ($Expand) { return [pscustomobject]@{ id='All'; displayName='All'; mailNickname='All' } } return 'All' }

			$fullObj = $null
			$resolvedId = $null

			if ($InputReference -match $script:guidRegex) {
				if ($script:groupDetailCache.ContainsKey($InputReference)) { if ($Expand) { return $script:groupDetailCache[$InputReference] } else { if ($DisplayName) { return ($script:groupDetailCache[$InputReference].displayName ?? $InputReference) }; return $script:groupDetailCache[$InputReference].id } }
				$fullObj = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/{0}?`$select=id,displayName,mailNickname" -f $InputReference)
				$resolvedId = $fullObj.id
			}
			elseif ($InputReference -match $script:mailNicknameRegex) {
				$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=mailNickname eq '{0}'&`$select=id,displayName,mailNickname" -f $InputReference)).value | Select-Object -First 1
				$resolvedId = $fullObj.id
			}
			else {
				$fullObj = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/groups/?`$filter=displayName eq '{0}'&`$select=id,displayName,mailNickname" -f $InputReference)).value | Select-Object -First 1
				$resolvedId = $fullObj.id
			}

			if (-not $resolvedId -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration['groups'].displayName) { $resolvedId = $InputReference }
			}

			if (-not $resolvedId) {
				if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve Group resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag failed; return $InputReference } else { throw "Cannot find group $InputReference" }
			}

			if (-not $Expand) { if ($DisplayName) { return ($fullObj.displayName ?? $InputReference) }; return $resolvedId }

			if (-not $fullObj) { $fullObj = [pscustomobject]@{ id=$resolvedId; displayName=$null; mailNickname=$null } }
			$detail = [pscustomobject]@{ id=$fullObj.id; displayName=$fullObj.displayName; mailNickname=$fullObj.mailNickname }
			foreach ($key in @($detail.id,$detail.displayName,$detail.mailNickname)) {
				if ($key -and -not $script:groupDetailCache.ContainsKey($key)) { $script:groupDetailCache[$key] = $detail }
			}
			return $detail
		}
		catch {
			if ($DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Group resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_
				return $InputReference
			} else {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve Group resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_
				$Cmdlet.ThrowTerminatingError($_)
			}
		}
	}
}
