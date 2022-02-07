function Resolve-AccessPackageAssignmentPolicy
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
		$AccessPackageAssignmentPolicyReference = Resolve-String -Text $AccessPackageAssignmentPolicyReference
	}
	process
	{			
		try {
			if ($AccessPackageAssignmentPolicyReference -match $script:guidRegex) {
				$accessPackageAssignmentPolicy = Get-MgEntitlementManagementAccessPackageAssignmentPolicy -AccessPackageAssignmentPolicyId $AccessPackageAssignmentPolicyReference
			}
			else {
				$accessPackageAssignmentPolicy = Get-MgEntitlementManagementAccessPackageAssignmentPolicy -Filter "displayName eq '$AccessPackageAssignmentPolicyReference'"
			}

			if (-Not $accessPackageAssignmentPolicy -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["accessPackageAssignmentPolicies"].displayName) {
					$accessPackageAssignmentPolicy = $InputReference
				}
			}
			
			if (-Not $accessPackageAssignmentPolicy -and -Not $DontFailIfNotExisting) { throw "Cannot find accessPackageAssignmentPolicy $AccessPackageAssignmentPolicyReference" } 
			elseif (-Not $accessPackageAssignmentPolicy -and $DontFailIfNotExisting) { return }

			if ($accessPackageAssignmentPolicy.count -gt 1) { throw "Got multiple Access Package Catalogs for $AccessPackageAssignmentPolicyReference" }
			return $accessPackageAssignmentPolicy
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "AccessPackageAssignmentPolicy" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
