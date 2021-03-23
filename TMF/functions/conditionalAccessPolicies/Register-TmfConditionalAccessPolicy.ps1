function Register-TmfConditionalAccessPolicy
{
	[CmdletBinding(DefaultParameterSetName = 'IPRanges')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,

		# Conditions
		[string[]] $includeUsers,
		[string[]] $excludeUsers,
		[string[]] $includeGroups,
		[string[]] $excludeGroups,
		[string[]] $includeRoles,
		[string[]] $includeApplications,
		[string[]] $excludeApplications,
		[string[]] $includeLocations,
		[string[]] $excludeLocations,
		[ValidateSet("android", "iOS", "windows", "windowsPhone", "macOS", "all")]
		[string[]] $includePlatforms,
		[ValidateSet("android", "iOS", "windows", "windowsPhone", "macOS", "all")]
		[string[]] $excludePlatforms,
		
		[ValidateSet("all", "browser", "mobileAppsAndDesktopClients", "exchangeActiveSync", "easSupported", "other")]
		[string[]] $clientAppTypes,
		[ValidateSet("low", "medium", "high", "hidden", "none")]
		[string[]] $userRiskLevels,
		[ValidateSet("low", "medium", "high", "hidden", "none")]
		[string[]] $signInRiskLevels,

		# Grant Controls
		[ValidateSet("block", "mfa", "compliantDevice", "domainJoinedDevice", "approvedApplication", "compliantApplication", "passwordChange", "unknownFutureValue")]
		[string[]] $buildInControls,
		[string[]] $customAuthenticationFactors,
		[ValidateSet("AND", "OR")]
		[string] $operator,
		[string[]] $termsOfUse,
		
		[Parameter(Mandatory = $true)]
		[ValidateSet("enabled", "disabled", "enabledForReportingButNotEnforced")]
		[string] $state,

		[bool] $present = $true,

		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "conditionalAccessPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | ? {$_.displayName -eq $displayName}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			displayName = $displayName
			state = $state
			present = $present
			sourceConfig = $sourceConfig
		}
		
		@(
			"includeUsers", "excludeUsers", "includeGroups", "excludeGroups",
			"includeRoles", "includeApplications", "excludeApplications",
			"includeLocations", "excludeLocations", "includePlatforms", "excludePlatforms",
			"clientAppTypes", "userRiskLevels", "signInRiskLevels", "buildInControls",
			"customAuthenticationFactors", "operator", "termsOfUse"
		) | foreach {
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
