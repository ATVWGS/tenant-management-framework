function Register-TmfAccessPackage
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string[]] $oldNames,
		[string] $description = "Access Package has been created with Tenant Management Framework",
		[bool] $isHidden = $false,
		[bool] $isRoleScopesVisible = $true,
		[Parameter(Mandatory = $true)]
		[string] $catalog,

		[object[]] $accessPackageResources,
		[object[]] $assignmentPolicies,

		[bool] $present = $true,		
		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessPackages"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{
			displayName = $displayName
			description = $description
			isHidden = $isHidden
			isRoleScopesVisible = $isRoleScopesVisible
			accessPackageResourceRoleScopes = @()
			catalog = $catalog
			present = $present
			sourceConfig = $sourceConfig
		}	

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}

		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		foreach ($policy in $assignmentPolicies) {
			$resource = $policy | Add-Member -NotePropertyMembers @{sourceConfig = $sourceConfig; accessPackage = $displayName; catalog = $catalog; present = $present} -PassThru | ConvertTo-PSFHashtable -Include $((Get-Command Register-TmfAccessPackageAssignmentPolicy).Parameters.Keys)			
			Register-TmfAccessPackageAssignmentPolicy @resource -Cmdlet $PSCmdlet
		}

		foreach ($accessPackageResource in $accessPackageResources) {
			$resource = $accessPackageResource | Add-Member -NotePropertyMembers @{sourceConfig = $sourceConfig; catalog = $catalog; displayName = ("{0} - {1}" -f $catalog, $accessPackageResource.resourceIdentifier)} -PassThru -Force | ConvertTo-PSFHashtable -Include $((Get-Command Register-TmfAccessPackageResource).Parameters.Keys)
			$object.accessPackageResourceRoleScopes += Register-TmfAccessPackageResource @resource -Cmdlet $PSCmdlet -PassThru
		}

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
	}
}
