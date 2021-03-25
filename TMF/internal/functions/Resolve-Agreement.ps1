function Resolve-Agreement
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
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
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/{0}" -f $InputReference)).Value
			}
			else {
				$group = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/agreements/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
			}

			if (!$group) { throw "Cannot find agreement $InputReference" }
			if ($group.count -gt 1) { throw "Got multiple agreements for $InputReference" }
			return $group.Id
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Agreement" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
