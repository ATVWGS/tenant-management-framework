function Resolve-Agreement
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
				$agreement = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/{0}" -f $InputReference)
			}
			else {
				$agreement = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (-Not $agreement -and -Not $DontFailIfNotExisting) { throw "Cannot find agreement $InputReference" } 
			elseif (-Not $location -and $DontFailIfNotExisting) { return }

			if ($agreement.count -gt 1 -and -not $providedId) { throw "Got multiple agreements for $InputReference" }
			return $agreement.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Agreement" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
