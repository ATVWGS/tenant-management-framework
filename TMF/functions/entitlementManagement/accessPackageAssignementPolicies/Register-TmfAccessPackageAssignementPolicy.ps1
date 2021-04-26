function Register-TmfAccessPackageAssignementPolicy
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string] $description = "Access Package Assignement Policy has been created with Tenant Management Framework",
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
		$resourceName = "accessPackageAssignementPolicies"
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

		"accessReviewSettings", "requestApprovalSettings", "requestorSettings" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				if ($script:validateFunctionMapping.ContainsKey($_)) {
					$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:validateFunctionMapping[$_].Parameters.Keys)
					$validated = & $script:validateFunctionMapping[$_] @validated -Cmdlet $Cmdlet
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
