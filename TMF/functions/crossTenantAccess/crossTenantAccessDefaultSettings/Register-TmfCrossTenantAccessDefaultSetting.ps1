function Register-TmfCrossTenantAccessDefaultSetting
{
	[CmdletBinding()]
	Param (
		[string] $displayName = "CrossTenantAccessDefaultSettings",
        [object] $automaticUserConsentSettings,
        [object] $b2bCollaborationInbound,
        [object] $b2bCollaborationOutbound,
        [object] $b2bDirectConnectInbound,
        [object] $b2bDirectConnectOutbound,
        [object] $inboundTrust,
        [object] $invitationRedemptionIdentityProviderConfiguration,
        [bool] $isServiceDefault = $true,
        [object] $tenantRestrictions,
		[bool] $present = $true,		
		[string] $sourceConfig = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "crossTenantAccessDefaultSettings"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{
			displayName = $displayName
            automaticUserConsentSettings = $automaticUserConsentSettings
            b2bCollaborationInbound = $b2bCollaborationInbound
            b2bCollaborationOutbound = $b2bCollaborationOutbound
            b2bDirectConnectInbound = $b2bDirectConnectInbound
            b2bDirectConnectOutbound = $b2bDirectConnectOutbound
            inboundTrust = $inboundTrust
            invitationRedemptionIdentityProviderConfiguration = $invitationRedemptionIdentityProviderConfiguration
            isServiceDefault = $isServiceDefault
            tenantRestrictions = $tenantRestrictions
			present = $present
			sourceConfig = $sourceConfig
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
