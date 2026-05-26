function Register-TmfActivityBasedTimeoutPolicy {
    [CmdletBinding()]
	Param (
		[string] $displayName,
        [Parameter(Mandatory = $true)]
        [string[]] $definition,
        [Parameter(Mandatory = $true)]
        [bool] $isOrganizationDefault,
        [bool] $present = $true,
        [string] $sourceConfig = "<Custom>",
        [string] $sourceFile = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "activityBasedTimeoutPolicies"
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
            definition = $definition
            isOrganizationDefault = $isOrganizationDefault
            present = $present
			sourceConfig = $sourceConfig
            sourceFile = $sourceFile
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