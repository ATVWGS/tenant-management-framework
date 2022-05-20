function Register-TmfGroup
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string[]] $oldNames,
		[string] $description = "Group has been created with Tenant Management Framework",		
		[string[]] $groupTypes = @(),
		[bool] $securityEnabled = $true,
		[bool] $mailEnabled = $false,
		[bool] $isAssignableToRole,		
		[string] $mailNickname = $displayName.Replace(" ",""),
		[Parameter(Mandatory = $true, ParameterSetName = "DynamicMembership")]
		[string] $membershipRule,		
		[Parameter(ParameterSetName = "Default")]
		[string[]] $members,
		[string[]] $owners,		
		[ValidateSet("AllowOnlyMembersToPost", "HideGroupInOutlook", "SubscribeNewGroupMembers", "WelcomeEmailDisabled")]		
		[string[]] $resourceBehaviorOptions,
		[bool] $privilegedAccess,
		[bool] $hideFromAddressLists,
		[bool] $hideFromOutlookClients,
		[object[]] $assignedLicenses,
		[bool] $present = $true,
		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "groups"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}

		try {
			if ($groupTypes -notcontains "Unified" -and $PSBoundParameters.ContainsKey('resourceBehaviorOptions')) {				
				throw "You can only define resourceBehaviorOptions for Unified groups."
			}
	
			if (
				($groupTypes -contains "DynamicMembership" -and -not $PSBoundParameters.ContainsKey('membershipRule')) -or
				($groupTypes -notcontains "DynamicMembership" -and $PSBoundParameters.ContainsKey('membershipRule'))
			) {
				throw "If you want to define a dynamic group, you need to provide a membershipRule and add the group type DynamicMembership in your configuration."
			}
		}
		catch {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "Group" -FunctionName $Cmdlet.CommandRuntime
			$Cmdlet.ThrowTerminatingError($_)
		}		
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }		

		$object = [PSCustomObject] @{
			displayName = Resolve-String -Text $displayName			
			description = $description
			groupTypes = $groupTypes
			securityEnabled = $securityEnabled
			mailEnabled = $mailEnabled			
			mailNickname = $mailNickname						
			present = $present
			sourceConfig = $sourceConfig
		}

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}

		"owners", "members", "membershipRule", "isAssignableToRole", "privilegedAccess", "hideFromAddressLists", "hideFromOutlookClients", "resourceBehaviorOptions" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
		}

		if ($PSBoundParameters.ContainsKey("assignedLicenses")) {
			$assignedLicenses = @($assignedLicenses | Foreach-Object {
				Validate-AssignedLicense -skuId $_.skuId -disabledPlans $_.disabledPlans
			})
			Add-Member -InputObject $object -MemberType NoteProperty -Name "assignedLicenses" -Value $assignedLicenses
		}
		
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}		
	}
}
