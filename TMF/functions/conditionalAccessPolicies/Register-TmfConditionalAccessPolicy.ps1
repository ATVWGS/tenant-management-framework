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
		[ValidateSet("android", "iOS", "windows", "windowsPhone", "macOS", "linux", "all")]
		[string[]] $includePlatforms,
		[ValidateSet("android", "iOS", "windows", "windowsPhone", "macOS", "linux", "all")]
		[string[]] $excludePlatforms,
		[ValidateSet("All")]
		[string[]] $includeDevices,
		[ValidateSet("Compliant", "DomainJoined")]
		[string[]] $excludeDevices,		
		[object] $deviceFilter,
		[object] $conditions,
		
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
		
		# Session Controls
		[object] $sessionControls,

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
		Test-GraphConnection -Cmdlet $Cmdlet
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
			if (($includeDevices -or $excludeDevices) -and $deviceFilter) {
				throw "It is not allowed to provide includeDevices/excludeDevices and a deviceFilter."
			}
		}
		catch {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "ConditionalAccess" -Tag "failed" -ErrorRecord $_ -FunctionName $Cmdlet.CommandRuntime			
			$cmdlet.ThrowTerminatingError($_)
		}

		$childPropertyToParentMapping = @{
			<# Workaround to support legacy conditionalAccessPolicy definition structure... #>
			"Users" = @("includeUsers", "excludeUsers", "includeGroups", "excludeGroups", "includeRoles", "excludeRoles")
			"Applications" = @("includeApplications", "excludeApplications")
			"Locations" = @("includeLocations", "excludeLocations")
			"Devices" = @("includeDevices", "excludeDevices", "deviceFilter")
			"Platforms" = @("includePlatforms", "excludePlatforms")
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

		if ($present) {
			if (-Not $conditions) {
				<# Workaround to support legacy conditionalAccessPolicy definition structure... #>
				$PSBoundParameters["conditions"] = @{}
				foreach ($mapping in $childPropertyToParentMapping.GetEnumerator()) {
					foreach ($value in $mapping.Value) {
						if ($PSBoundParameters.ContainsKey($value)) {
							if (-Not $PSBoundParameters["conditions"][$mapping.Key]) { $PSBoundParameters["conditions"][$mapping.Key] = @{}}
							$PSBoundParameters["conditions"][$mapping.Key][$value] = $PSBoundParameters[$value]
						}
					}
				}
				"clientAppTypes", "userRiskLevels", "signInRiskLevels" | ForEach-Object {
					if ($PSBoundParameters.ContainsKey($_)) {
						$PSBoundParameters["conditions"][$_] = $PSBoundParameters[$_]
					}
				}
			}

			if (-Not $grantControls -and ($builtInControls -or $customAuthenticationFactors -or $operator -or $termsOfUse)) {
				<# Workaround to support legacy conditionalAccessPolicy definition structure... #>
				$PSBoundParameters["grantControls"]	= @{}
				"builtInControls", "customAuthenticationFactors", "operator", "termsOfUse" | ForEach-Object {
					if ($PSBoundParameters.ContainsKey($_)) {
						$PSBoundParameters["grantControls"][$_] = $PSBoundParameters[$_]
					}
				}
			}

			"grantControls", "sessionControls", "conditions" | ForEach-Object {
				if ($PSBoundParameters.ContainsKey($_)) {
					if ($script:supportedResources[$resourceName]["validateFunctions"].ContainsKey($_)) {
						$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$_].Parameters.Keys)
						$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$_] @validated -Cmdlet $Cmdlet
					}
					else {
						$validated = $PSBoundParameters[$_]
					}
					Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
				}			
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
