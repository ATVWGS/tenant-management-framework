function Resolve-Application
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
				$application = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}" -f $InputReference)
			}
			elseif ($InputReference -in @("All", "Office365")) {
				return $InputReference
			}
			else {
				$application = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=(displayName eq '{0}') and (servicePrincipalType eq 'Application')" -f $InputReference)).Value
			}

			if (-Not $application -and -Not $DontFailIfNotExisting) { throw "Cannot find application $InputReference" } 
			elseif (-Not $application -and $DontFailIfNotExisting) { return }

			if ($application.count -gt 1 -and -not $providedId) { throw "Got multiple applications for $InputReference" }
			return $application.appId
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Application" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
