function Resolve-NamedLocation
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		try {
			if ($InputReference -match $script:guidRegex) {
				$providedId = $true
				$location = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations/{0}" -f $InputReference)
			}
			elseif ($InputReference -in @("All", "AllTrusted")) {
				return $InputReference
			}
			else {
				$location = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identity/conditionalAccess/namedLocations/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (-Not $location -and -Not $DontFailIfNotExisting) { throw "Cannot find namedLocation $InputReference" } 
			elseif (-Not $location -and $DontFailIfNotExisting) { return }

			if ($location.count -gt 1 -and -not $providedId) { throw "Got multiple namedLocations for $InputReference" }
			return $location.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "NamedLocation" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
