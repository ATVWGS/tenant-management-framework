function Register-TmfConditionalAccessPolicy
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string[]] $oldNames,

		# Conditions
		[string[]] $includeUsers,
		[string[]] $excludeUsers,
		[string[]] $includeGroups,
		[string[]] $excludeGroups,
		[string[]] $includeRoles,
		[string[]] $excludeRoles,
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
		[object] $grantControls,		
		[ValidateSet("block", "mfa", "compliantDevice", "domainJoinedDevice", "approvedApplication", "compliantApplication", "passwordChange", "unknownFutureValue")]		
		[string[]] $builtInControls,		
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
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}

		try {
			if ($grantControls -and ($builtInControls -or $customAuthenticationFactors -or $operator -or $termsOfUse)) {
				<# Workaround to support old conditionalAccessPolicy definition structure... #>
				throw "It is not allowed to specify grantControls and grantControl child properties (builtInControls, operator, customAuthenticationFactors, termsOfUse) at the same time."
			}
			if (($buildInControls -and -not $operator) -or ($termsOfUse -and -not $operator)) {
				throw "You need to provide an operator (AND or OR) if you want to use buildInControls or termsofUse."
			}
		}
		catch {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "ConditionalAccess" -Tag "failed" -ErrorRecord $_ -FunctionName $Cmdlet.CommandRuntime			
			$cmdlet.ThrowTerminatingError($_)
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

		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
		}
		
		@(
			"includeUsers", "excludeUsers", "includeGroups", "excludeGroups",
			"includeRoles", "excludeRoles", "includeApplications", "excludeApplications",
			"includeLocations", "excludeLocations", "includePlatforms", "excludePlatforms",
			"clientAppTypes", "userRiskLevels", "signInRiskLevels"
		) | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
		}
		
		if (-Not $grantControls -and ($builtInControls -or $customAuthenticationFactors -or $operator -or $termsOfUse)) {
			<# Workaround to support old conditionalAccessPolicy definition structure... #>
			$PSBoundParameters["grantControls"]	= @{}
			"builtInControls", "customAuthenticationFactors", "operator", "termsOfUse" | ForEach-Object {
				if ($PSBoundParameters.ContainsKey($_)) {
					$PSBoundParameters["grantControls"][$_] = $PSBoundParameters[$_]
				}
			}
		}

		"grantControls", "sessionControls" | ForEach-Object {
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

		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}		
	}
}
