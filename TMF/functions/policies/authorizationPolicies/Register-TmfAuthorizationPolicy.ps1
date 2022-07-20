function Register-TmfAuthorizationPolicy {
    [CmdletBinding()]
	Param (
		[string] $displayName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("everyone", "adminsAndGuestInviters", "adminsGuestInvitersAndAllMembers", "none")]
        [string] $allowInvitesFrom,
        [Parameter(Mandatory = $true)]
        [bool] $allowedToSignUpEmailBasedSubscriptions,
        [Parameter(Mandatory = $true)]
        [bool] $allowedToUseSSPR,
        [Parameter(Mandatory = $true)]
        [bool] $allowEmailVerifiedUsersToJoinOrganization,
        [Parameter(Mandatory = $true)]
        [bool] $blockMsolPowerShell,
        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Guest User", "Restricted Guest User")]
        [string] $guestUserRole,
        [Parameter(Mandatory = $true)]
        [bool] $allowedToCreateApps,
        [Parameter(Mandatory = $true)]
        [bool] $allowedToCreateSecurityGroups,
        [Parameter(Mandatory = $true)]
        [bool] $allowedToReadOtherUsers,
        [Parameter(Mandatory = $true)]
        [bool] $allowedToReadBitlockerKeysForOwnedDevice,
        [string []] $permissionGrantPolicyIdsAssignedToDefaultUserRole = @(),	
        [string] $sourceConfig = "<Custom>",		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "authorizationPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}

    process { 
        if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{		
			displayName = $displayName
			allowInvitesFrom = $allowInvitesFrom
			allowedToSignUpEmailBasedSubscriptions = $allowedToSignUpEmailBasedSubscriptions
			allowedToUseSSPR = $allowedToUseSSPR
			allowEmailVerifiedUsersToJoinOrganization = $allowEmailVerifiedUsersToJoinOrganization
            blockMsolPowerShell = $blockMsolPowerShell
            permissionGrantPolicyIdsAssignedToDefaultUserRole = $permissionGrantPolicyIdsAssignedToDefaultUserRole            
            defaultUserRolePermissions = @{
                allowedToCreateApps = $allowedToCreateApps
                allowedToCreateSecurityGroups = $allowedToCreateSecurityGroups
                allowedToReadOtherUsers = $allowedToReadOtherUsers
                allowedToReadBitlockerKeysForOwnedDevice = $allowedToReadBitlockerKeysForOwnedDevice
            }
			sourceConfig = $sourceConfig
		}

        switch ($guestUserRole) {
            "User" {Add-Member -InputObject $object -MemberType NoteProperty -Name "guestUserRoleId" -Value "a0b1b346-4d3e-4e8b-98f8-753987be4970"}
            "Guest User" {Add-Member -InputObject $object -MemberType NoteProperty -Name "guestUserRoleId" -Value "10dae51f-b6af-4016-8d66-8c2a99b929b3"}
            "Restricted Guest User" {Add-Member -InputObject $object -MemberType NoteProperty -Name "guestUserRoleId" -Value "2af84b1e-32c8-42b7-82bc-daa82404023b"}
        }

        Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
    }

    end {}
}