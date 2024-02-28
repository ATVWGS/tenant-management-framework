function Resolve-AdministrativeUnit
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
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
				$administrativeUnit = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits?`$filter=id eq '{0}'" -f $InputReference)).Value.Id
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$administrativeUnit = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $administrativeUnit -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["administrativeUnits"].displayName) {
					$administrativeUnit = $InputReference
				}
			}

			if (-Not $administrativeUnit -and -Not $DontFailIfNotExisting) { throw "Cannot find administrativeUnit $InputReference." } 
			elseif (-Not $administrativeUnit -and $DontFailIfNotExisting) { return }

			if ($administrativeUnit.count -gt 1) { throw "Got multiple administrativeUnits for $InputReference" }
			return $administrativeUnit
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AdministrativeUnit" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
