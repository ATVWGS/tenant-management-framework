function Register-TmfDirectorySetting {
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "BannedPasswordCheckOnPremisesMode")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "BannedPasswordList")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUsernameAndPasswordParams", "")]
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateSet("Application","Password Rule Settings","Group.Unified","Prohibited Names Settings","Custom Policy Settings","Consent Policy Settings")]
		[string] $displayName,
		[Parameter(Mandatory = $true, ParameterSetName = "Application")]
		[bool] $EnableAccessCheckForPrivilegedApplicationUpdates,
		[Parameter(Mandatory = $true, ParameterSetName = "Password Rule Settings")]
		[string] $BannedPasswordCheckOnPremisesMode,
		[Parameter(Mandatory = $true, ParameterSetName = "Password Rule Settings")]
		[bool] $EnableBannedPasswordCheckOnPremises,
		[Parameter(Mandatory = $true, ParameterSetName = "Password Rule Settings")]
		[bool] $EnableBannedPasswordCheck,
		[Parameter(Mandatory = $true, ParameterSetName = "Password Rule Settings")]
		[int32] $LockoutDurationInSeconds,
		[Parameter(Mandatory = $true, ParameterSetName = "Password Rule Settings")]
		[int32] $LockoutThreshold,
		[Parameter(Mandatory = $true, ParameterSetName = "Password Rule Settings")]
		[AllowEmptyString()]
		[string] $BannedPasswordList,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $AllowToAddGuests,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $NewUnifiedGroupWritebackDefault,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $EnableMIPLabels,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $CustomBlockedWordsList,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $EnableMSStandardBlockedWords,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $ClassificationDescriptions,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $DefaultClassification,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $PrefixSuffixNamingRequirement,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $AllowGuestsToBeGroupOwner,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $AllowGuestsToAccessGroups,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $GuestUsageGuidelinesUrl,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $GroupCreationAllowedGroupId,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $UsageGuidelinesUrl,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[AllowEmptyString()]
		[string] $ClassificationList,
		[Parameter(Mandatory = $true, ParameterSetName = "Group.Unified")]
		[bool] $EnableGroupCreation,
		[Parameter(Mandatory = $true, ParameterSetName = "Prohibited Names Settings")]
		[AllowEmptyString()]
		[string] $CustomBlockedSubStringsList,
		[Parameter(Mandatory = $true, ParameterSetName = "Prohibited Names Settings")]
		[AllowEmptyString()]
		[string] $CustomBlockedWholeWordsList,
		[Parameter(Mandatory = $true, ParameterSetName = "Custom Policy Settings")]
		[AllowEmptyString()]
		[string] $CustomConditionalAccessPolicyUrl,
		[Parameter(Mandatory = $true, ParameterSetName = "Consent Policy Settings")]
		[bool] $BlockUserConsentForRiskyApps,
		[Parameter(Mandatory = $true, ParameterSetName = "Consent Policy Settings")]
		[bool] $EnableAdminConsentRequests,
		[string] $sourceConfig = "<Custom>",
		[bool] $present = $true,			
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "directorySettings"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}

    process {
        if (Test-PSFFunctionInterrupt) { return }				

		$directorySettingsTemplate = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/directorySettingTemplates").value | Where-Object {$_.displayName -eq $displayName}

		$object = [PSCustomObject] @{
			present = $present
			displayName = $displayName
			templateId = $directorySettingsTemplate.id
        }

		foreach ($templateParameter in $directorySettingsTemplate.values.name) {
			#Exlude non-setable parameters
			if ($templateParameter -ne "EnableGroupSpecificConsent" -and $templateParameter -ne "ConstrainGroupSpecificConsentToMembersOfGroupId") {
				Add-Member -InputObject $object -MemberType NoteProperty -Name $templateParameter -Value $((Get-Variable -Name $templateParameter).value)
			}			
		}

        Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name };

        if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
    }

    end {}
}