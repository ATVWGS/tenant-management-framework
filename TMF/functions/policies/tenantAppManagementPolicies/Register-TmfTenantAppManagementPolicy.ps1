function Register-TmfTenantAppManagementPolicy {
    [CmdletBinding()]
	Param (
        [Parameter(Mandatory)]
        [string] $displayName,
        [string] $description,
        [Parameter(Mandatory)]
        [bool] $isEnabled,
        [Parameter(Mandatory)]
        [object] $applicationRestrictions,
        [Parameter(Mandatory)]
        [object] $servicePrincipalRestrictions,
        [bool] $present = $true,
        [string] $sourceConfig = "<Custom>",		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "tenantAppManagementPolicy"
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
			isEnabled = $isEnabled
            applicationRestrictions = $applicationRestrictions
            servicePrincipalRestrictions = $servicePrincipalRestrictions
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

    end {}
}