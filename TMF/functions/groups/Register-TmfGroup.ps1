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
		$resourceName = "groups"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}

		if (
			($groupTypes -contains "DynamicMembership" -and -not $PSBoundParameters.ContainsKey('membershipRule')) -or
			($groupTypes -notcontains "DynamicMembership" -and $PSBoundParameters.ContainsKey('membershipRule'))
		) {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "Group" -FunctionName $Cmdlet.CommandRuntime
			$exception = New-Object System.Data.DataException("If you want to define a dynamic group, you need to provide a membershipRule and add the group type DynamicMembership in your configuration.")
			$errorID = 'PropertySetNotPossible'
			$category = [System.Management.Automation.ErrorCategory]::NotSpecified
			$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
			$cmdlet.ThrowTerminatingError($recordObject)
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }		

		$object = [PSCustomObject] @{
			displayName = Resolve-String -Text $displayName
			oldNames = $oldNames | ForEach-Object {Resolve-String $_}
			description = $description
			groupTypes = $groupTypes
			securityEnabled = $securityEnabled
			mailEnabled = $mailEnabled			
			mailNickname = $mailNickname						
			present = $present
			sourceConfig = $sourceConfig
		}

		"owners", "members", "membershipRule", "isAssignableToRole" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
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
