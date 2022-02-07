function Resolve-Application
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
				$application = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}" -f $InputReference)).Value.appId
			}
			elseif ($InputReference -in @("All", "Office365")) {
				return $InputReference
			}
			else {
				$application = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=(displayName eq '{0}') and (servicePrincipalType eq 'Application')" -f $InputReference)).Value.appId
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
