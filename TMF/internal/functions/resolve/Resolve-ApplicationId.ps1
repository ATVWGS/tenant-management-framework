function Resolve-ApplicationId
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
				$application = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/{0}" -f $InputReference)).Value.id
			}
			elseif ($InputReference -in @("All", "Office365")) {
				return $InputReference
			}
			else {
				$application = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/applications/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.id
			}

			if (-Not $application -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["applications"].displayName) {
					$application = $InputReference
				}
			}

			if (-Not $application -and -Not $DontFailIfNotExisting) { throw "Cannot find application $InputReference" } 
			elseif (-Not $application -and $DontFailIfNotExisting) { return }

			if ($application.count -gt 1) { throw "Got multiple applications for $InputReference" }
			return $application
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Application" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
