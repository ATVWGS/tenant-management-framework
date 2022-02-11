function Register-TmfAdministrativeUnit
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string[]] $oldNames,

		[string] $description,
        [string] $visibility,
        
        [string[]] $members,
        [string[]] $groups,

        [object[]] $scopedRoleMembers,
		[bool] $present = $true,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "administrativeUnits"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @();
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName};
		}
		if(!$visibility){
				$visibility = "Public";
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return; }

		$object = [PSCustomObject] @{
			displayName = Resolve-String -Text $displayName
			description = $description
			visibility = $visibility
			present = $present
		}

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}

		"members", "groups", "scopedRoleMembers" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_];
			}
		}
		
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name };

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object;
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object;
		}
	}
}
