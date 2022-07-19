function Register-TmfAuthenticationFlowsPolicy {
    [CmdletBinding()]
	Param (
        [string] $displayName,
        [bool] $selfServiceSignUpEnabled,
        [string] $sourceConfig = "<Custom>",		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "authenticationFlowsPolicies"
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
			selfServiceSignUp = @{
                isEnabled = $selfServiceSignUpEnabled
            }
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

    end {}
}