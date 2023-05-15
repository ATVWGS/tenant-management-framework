function Register-TmfAppManagementPolicy {
    [CmdletBinding()]
	Param (
        [Parameter(Mandatory)]
        [string] $displayName,
        [string] $description = "AppManagementPolicy created by Tenant Management Framework",
        [Parameter(Mandatory)]
        [bool] $isEnabled,
        [Parameter(Mandatory)]
        [object] $restrictions,
        [string[]] $appliesTo,
        [bool] $present = $true,
        [string] $sourceConfig = "<Custom>",		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "appManagementPolicies"
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
            restrictions = $restrictions
            present = $present
			sourceConfig = $sourceConfig
		}
        
        if ($PSBoundParameters.ContainsKey("appliesTo")) {
            Add-Member -InputObject $object -MemberType NoteProperty -Name "appliesTo" -Value @($appliesTo | ForEach-Object {Resolve-ApplicationId -InputReference $_ })
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