function Register-TmfAccessPackageAssignmentPolicy
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string[]] $oldNames,
		[string] $description = "Access Package Assignment Policy has been created with Tenant Management Framework",
		[Parameter(Mandatory = $true)]
		[string] $accessPackage,

		[bool] $canExtend = $false,
		[Parameter(Mandatory = $true)]
		[int] $durationInDays = 7,

		[object] $accessReviewSettings,
		[object] $requestApprovalSettings,
		[object] $requestorSettings,
		
		[bool] $present = $true,		
		[string] $sourceConfig = "<Custom>",

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
			canExtend = $canExtend
			durationInDays = $durationInDays
			present = $present
			sourceConfig = $sourceConfig
		}

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}

		"accessReviewSettings", "requestApprovalSettings", "requestorSettings" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				if ($script:supportedResources[$resourceName]["validateFunctions"].ContainsKey($_)) {
					$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$_].Parameters.Keys)
					$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$_] @validated -Cmdlet $Cmdlet
				}
				else {
					$validated = $PSBoundParameters[$_]
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
