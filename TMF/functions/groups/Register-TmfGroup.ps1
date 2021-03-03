function Register-TmfGroup
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string] $description = "Group has been created with Tenant Management Framework",
		[string[]] $groupTypes = @(),
		[bool] $securityEnabled = $true,
		[bool] $mailEnabled = $false,
		[Parameter(Mandatory = $true)]
		[string] $mailNickname = $displayName.Replace(" ",""),
		[Parameter(Mandatory = $true, ParameterSetName = "DynamicMembership")]
		[string] $membershipRule,
		[Parameter(ParameterSetName = "Default")]
		[string[]] $members,
		[string[]] $owners,
		[bool] $present = $true,
		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		if (!$script:desiredConfiguration["groups"]) {
			$script:desiredConfiguration["groups"] = @()
		}
		if ($script:desiredConfiguration["groups"].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration["groups"] | ? {$_.displayName -eq $displayName}
			if ($alreadyLoaded.sourceConfig -ne $sourceConfig) {
				Stop-PSFFunction -String "TMF.RegisterComponent.AlreadyLoaded" -StringValues "group", $displayName, $alreadyLoaded.sourceConfig
			}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		if ($groupTypes -contains "DynamicMembership" -and -not $membershipRule) {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "Group" -FunctionName $Cmdlet.CommandRuntime
			$exception = New-Object System.Data.DataException("If you want to define dynamic group, you need to provide a membershipRule in your configuration.")
			$errorID = 'DynamicMembershipRuleMissing'
			$category = [System.Management.Automation.ErrorCategory]::NotSpecified
			$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
			$cmdlet.ThrowTerminatingError($recordObject)
		}

		$object = [PSCustomObject] @{
			displayName = $displayName
			description = $description
			groupTypes = $groupTypes
			securityEnabled = $securityEnabled
			mailEnabled = $mailEnabled
			mailNickname = $mailNickname						
			present = $present
			sourceConfig = $sourceConfig
		}

		if ($members) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name members -Value $members
		}
		elseif ($membershipRule) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name membershipRule -Value $membershipRule
		}
		if ($owners) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name owners -Value $owners
		}
		
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration["groups"][$script:desiredConfiguration["groups"].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration["groups"] += $object
		}		
	}
}
