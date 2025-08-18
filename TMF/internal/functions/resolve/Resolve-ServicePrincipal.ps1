function Resolve-ServicePrincipal
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand,
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{
		try {
			if (-not $Expand -and -not $DisplayName -and $script:servicePrincipalDetailCache -and $script:servicePrincipalDetailCache.ContainsKey($InputReference)) { return $script:servicePrincipalDetailCache[$InputReference].id }
			if (-not $Expand -and $DisplayName -and $script:servicePrincipalDetailCache -and $script:servicePrincipalDetailCache.ContainsKey($InputReference)) { return ($script:servicePrincipalDetailCache[$InputReference].displayName ?? $InputReference) }
			$detail = $null
			if ($InputReference -match $script:guidRegex) {
				$detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}?`$select=id,displayName" -f $InputReference)
				$servicePrincipal = $detail.Id
			}
			else {
				$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=displayName eq '{0}'&`$select=id,displayName" -f $InputReference)).Value | Select-Object -First 1
				$servicePrincipal = $detail.Id
			}

			if (-Not $servicePrincipal -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["servicePrincipals"].displayName) {
					$servicePrincipal = $InputReference
				}
			}

			if (-Not $servicePrincipal -and -Not $DontFailIfNotExisting) { throw "Cannot find servicePrincipal $InputReference" } 
			elseif (-Not $servicePrincipal -and $DontFailIfNotExisting) {
				Write-PSFMessage -Level Warning -Message ("Cannot resolve ServicePrincipal resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag 'failed'
				return $InputReference
			}

			if ($servicePrincipal.count -gt 1) { throw "Got multiple servicePrincipals for $InputReference" }
			if ($DisplayName -and -not $Expand) { return ($detail.displayName ?? $InputReference) }
			if ($Expand) {
				if (-not $script:servicePrincipalDetailCache) { $script:servicePrincipalDetailCache = @{} }
				$spDetail = [pscustomobject]@{ id=$servicePrincipal; displayName=$detail.displayName }
				foreach ($key in @($spDetail.id,$spDetail.displayName)) { if ($key -and -not $script:servicePrincipalDetailCache.ContainsKey($key)) { $script:servicePrincipalDetailCache[$key] = $spDetail } }
				return $spDetail
			}
			return $servicePrincipal
		}
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve servicePrincipal resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
