function Resolve-Agreement
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
				$agreement = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/{0}" -f $InputReference)).Value.Id
			}
			else {
				$agreement = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $agreement -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["agreements"].displayName) {
					$agreement = $InputReference
				}
			}

			elseif (-Not $agreement -and -Not $DontFailIfNotExisting) { throw "Cannot find agreement $InputReference" } 
			elseif (-Not $location -and $DontFailIfNotExisting) { return }

			if ($agreement.count -gt 1) { throw "Got multiple agreements for $InputReference" }
			return $agreement
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Agreement" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
