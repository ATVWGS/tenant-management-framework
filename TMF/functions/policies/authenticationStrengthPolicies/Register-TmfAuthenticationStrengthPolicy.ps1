function Register-TmfAuthenticationStrengthPolicy {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string] $description="Authentication strength policy created by Tenant Management Framework",
		[Parameter(Mandatory = $true)]
        [string[]] $allowedCombinations,
		[bool] $present = $true,
        [string] $sourceConfig = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "authenticationStrengthPolicies"
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
			description = $description
			policyType = "custom"
			present = $present
            sourceConfig = $sourceConfig
        }

		#Verify that only allowed authentication combinations are used
		$allowedAuthenticationCombinations = (Invoke-MgGraphRequest -Method GET -Uri "https://$graphBaseUrl/identity/conditionalAccess/authenticationStrength/combinations").value

		foreach ($allowedCombination in $allowedCombinations) {
			if ($allowedAuthenticationCombinations -notcontains $allowedCombination) {
				throw "Authentication strength policy $displayname contains the following unallowed authentication combination: $allowedCombination"
			}
		}

		Add-Member -InputObject $object -MemberType NoteProperty -Name allowedCombinations -Value $allowedCombinations		
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