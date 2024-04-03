function Resolve-CustomSecurityAttributeDefinition
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
			$customSecurityAttributeDefinition = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directory/customSecurityAttributeDefinitions/{0}" -f $InputReference)).Id

			if ($customSecurityAttributeDefinition.count -gt 1) { throw "Got multiple customSecurityAttributeDefinitions for $InputReference" }
		}
		catch {
			$failed = $true
		}
		finally {
			if ($SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["customSecurityAttributeDefinitions"].displayName) {
					$customSecurityAttributeDefinition = $InputReference
				}
			}
			else {
				if (-Not $DontFailIfNotExisting) { 
					Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "customSecurityAttributeDefinition" -Tag 'failed' -ErrorRecord $_
					$Cmdlet.ThrowTerminatingError($_)
				}				
			}			
		}
		return $customSecurityAttributeDefinition
	}
}
