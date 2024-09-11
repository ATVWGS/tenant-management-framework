function Register-TmfAdministrativeUnit
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string[]] $oldNames,

		[string] $description,
        [string] $visibility,
        
		[string] $membershipType = "assigned",
		[Parameter(ParameterSetName="dynamic")]
		[string] $membershipRule,
		[Parameter(ParameterSetName="dynamic")]
		[string] $membershipRuleProcessingState,

		[Parameter(ParameterSetName="assigned")]
        [string[]] $members,
		[Parameter(ParameterSetName="assigned")]
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
			membershipType = $membershipType
			present = $present
		}

		if (($membershipType -eq "dynamic" -and (-not $PSBoundParameters.ContainsKey("membershipRule"))) -or ($membershipType -eq "assigned" -and ($PSBoundParameters.ContainsKey("membershipRule") -or $PSBoundParameters.ContainsKey("membershipRuleProcessingState")))) {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "admininstrativeUnit" -Tag "failed" -FunctionName $Cmdlet.CommandRuntime
			$ErrorObject = New-Object Management.Automation.ErrorRecord "The provided property set for `"$($displayName)`" (Type: administrativeUnit) is not applicable.", "1", 'InvalidData', $object
			$cmdlet.ThrowTerminatingError($ErrorObject)
		}

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}

		"members", "groups", "scopedRoleMembers", "membershipRule", "membershipRuleProcessingState" | ForEach-Object {
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
