function Validate-ConditionalAccessUsers
{
	[CmdletBinding()]
	Param (
		[string[]] $includeUsers,
		[string[]] $excludeUsers,
		[string[]] $includeGroups,
		[string[]] $excludeGroups,
		[string[]] $includeRoles,
		[string[]] $excludeRoles,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$parentResourceName = "conditionalAccessPolicies"
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {
			if ($property.Key -in @("includeUsers", "excludeUsers")) {
				$validated = @($property.Value | Foreach-Object {Resolve-User -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
			}
			if ($property.Key -in @("includeGroups", "excludeGroups")) {
				$validated = @($property.Value | Foreach-Object {Resolve-Group -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
			}
			if ($property.Key -in @("includeRoles", "excludeRoles")) {
				$validated = @($property.Value | Foreach-Object {Resolve-DirectoryRoleTemplate -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
			}
			$hashtable[$property.Key] = $validated
		}
	}
	end
	{
		$hashtable
	}
}
