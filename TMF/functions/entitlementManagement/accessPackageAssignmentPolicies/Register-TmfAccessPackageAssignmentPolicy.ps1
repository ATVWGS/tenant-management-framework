function Register-TmfAccessPackageAssignmentPolicy
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "autoAssigned")]
		[Parameter(Mandatory = $true, ParameterSetName = "assigned")]
		[string] $displayName,
		[Parameter(ParameterSetName = "autoAssigned")]
		[Parameter(ParameterSetName = "assigned")]
		[string[]] $oldNames,
		[Parameter(ParameterSetName = "autoAssigned")]
		[Parameter(ParameterSetName = "assigned")]
		[string] $description = "Access Package Assignment Policy has been created with Tenant Management Framework",
		[Parameter(Mandatory = $true, ParameterSetName = "autoAssigned")]
		[Parameter(Mandatory = $true, ParameterSetName = "assigned")]
		[string] $accessPackage,
		[Parameter(Mandatory = $true, ParameterSetName = "autoAssigned")]
		[Parameter(Mandatory = $true, ParameterSetName = "assigned")]
		[ValidateSet("notSpecified","specificDirectoryUsers","specificConnectedOrganizationUsers","specificDirectoryServicePrincipals","allMemberUsers","allDirectoryUsers","allDirectoryServicePrincipals","allConfiguredConnectedOrganizationUsers","allExternalUsers","unknownFutureValue")]
		[string] $allowedTargetScope,
		[Parameter(Mandatory = $true, ParameterSetName = "autoAssigned")]
		[Parameter(ParameterSetName = "assigned")]
		[object[]] $specificAllowedTargets,
        [Parameter(Mandatory = $true, ParameterSetName = "assigned")]
        [object] $expiration,
		[Parameter(ParameterSetName = "assigned")]
		[object] $reviewSettings,
		[Parameter(ParameterSetName = "assigned")]
		[object] $requestApprovalSettings,
		[Parameter(ParameterSetName = "assigned")]
		[object] $requestorSettings,
		[Parameter(Mandatory = $true, ParameterSetName = "autoAssigned")]
		[object] $automaticRequestSettings, 
		[Parameter(ParameterSetName = "autoAssigned")]
		[Parameter(ParameterSetName = "assigned")]
		[bool] $present = $true,
		[Parameter(ParameterSetName = "autoAssigned")]
		[Parameter(ParameterSetName = "assigned")]
		[string] $sourceConfig = "<Custom>",
		[Parameter(ParameterSetName = "autoAssigned")]
		[Parameter(ParameterSetName = "assigned")]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessPackageAssignmentPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName -and $_.accessPackage -eq $accessPackage}) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName -and $_.accessPackage -eq $accessPackage}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{		
			displayName = $displayName
			accessPackage = $accessPackage
			description = $description
			allowedTargetScope = $allowedTargetScope
			present = $present
			sourceConfig = $sourceConfig
		}

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}

		"reviewSettings", "requestApprovalSettings", "requestorSettings", "specificAllowedTargets", "expiration", "automaticRequestSettings" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				if ($script:supportedResources[$resourceName]["validateFunctions"].ContainsKey($_)) {
					$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$_].Parameters.Keys)
					$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$_] @validated -Cmdlet $Cmdlet
				}
				else {
					$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable
				}
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
			}			
		}

		Add-Member -InputObject $object -MemberType ScriptMethod -Name accessPackageId -Value { Resolve-AccessPackage -InputReference $this.accessPackage -Cmdlet $Cmdlet -DontFailIfNotExisting }
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
	}
}
