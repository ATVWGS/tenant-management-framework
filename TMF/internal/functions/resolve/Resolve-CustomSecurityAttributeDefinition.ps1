function Resolve-CustomSecurityAttributeDefinition
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $SearchInDesiredConfiguration,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		$detail = $null; $id = $null
		try { $detail = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directory/customSecurityAttributeDefinitions/{0}?`$select=id,displayName" -f $InputReference); $id = $detail.id } catch { $id=$null }
		if (-not $id -and $SearchInDesiredConfiguration) { if ($InputReference -in $script:desiredConfiguration['customSecurityAttributeDefinitions'].displayName) { $id = $InputReference } }
		if (-not $id) { if ($DontFailIfNotExisting) { return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve customSecurityAttributeDefinition resource for input '{0}'. Searched tenant & desired configuration." -f $InputReference) -Tag failed; $Cmdlet.ThrowTerminatingError($_) } }
		if (-not $Expand) { if ($DisplayName) { return $detail.displayName } return $id }
		return [pscustomobject]@{ id=$id; displayName=$detail.displayName }
	}
}
