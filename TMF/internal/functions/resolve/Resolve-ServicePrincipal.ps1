function Resolve-ServicePrincipal
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
				$servicePrincipal = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/{0}" -f $InputReference)).Value.Id
			}
			else {
				$servicePrincipal = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/servicePrincipals/?`$filter=(displayName eq '{0}') and (servicePrincipalType eq 'Application')" -f $InputReference)).Value.Id
			}

			if (-Not $servicePrincipal -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["servicePrincipals"].displayName) {
					$servicePrincipal = $InputReference
				}
			}

			if (-Not $servicePrincipal -and -Not $DontFailIfNotExisting) { throw "Cannot find servicePrincipal $InputReference" } 
			elseif (-Not $servicePrincipal -and $DontFailIfNotExisting) { return }

			if ($servicePrincipal.count -gt 1) { throw "Got multiple servicePrincipals for $InputReference" }
			return $servicePrincipal
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "servicePrincipal" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
