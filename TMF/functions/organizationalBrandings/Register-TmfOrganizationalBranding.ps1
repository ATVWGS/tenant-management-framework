function Register-TmfOrganizationalBranding
{
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "customAccountResetCredentialsUrl")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "customForgotMyPasswordText")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUsernameAndPasswordParams", "customForgotMyPasswordText")]
	Param (
		[Parameter(Mandatory = $true)]
        [ValidatePattern('^(?:[a-z]{2}-[A-Z]{2}|default)$')]
		[string] $displayName,
		[string] $backgroundColor,		
		[string] $customAccountResetCredentialsUrl,
		[string] $customCannotAccessYourAccountText,
		[string] $customCannotAccessYourAccountUrl,
		[string] $customForgotMyPasswordText,
        [string] $customPrivacyAndCookiesText,
        [string] $customPrivacyAndCookiesUrl,
        [string] $customResetItNowText,
        [string] $customTermsOfUseText,
        [string] $customTermsOfUseUrl,
        [string] $headerBackgroundColor,
        [string] $signInPageText,
        [string] $usernameHintText,
        [bool] $present = $true,
		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )
    begin {
        $resourceName = "organizationalBranding"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
        if ($displayName -eq "default") {
            $AvailableParameters = @("backgroundColor","customAccountResetCredentialsUrl","customCannotAccessYourAccountText","customCannotAccessYourAccountUrl","customForgotMyPasswordText","customPrivacyAndCookiesText","customPrivacyAndCookiesUrl","customResetItNowText","customTermsOfUseText","customTermsOfUseUrl","headerBackgroundColor","signInPageText","usernameHintText")
        }
        else {
            $AvailableParameters = @("backgroundColor","signInPageText","usernameHintText")
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }		

		$object = [PSCustomObject] @{
			displayName = Resolve-String -Text $displayName			
            present = $present
            sourceConfig = $sourceConfig
		}

        foreach ($parameter in $AvailableParameters) {
            if ($PSBoundParameters.ContainsKey($parameter)) {
                Add-Member -InputObject $object -MemberType NoteProperty -Name $parameter -Value $PSBoundParameters[$parameter]
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