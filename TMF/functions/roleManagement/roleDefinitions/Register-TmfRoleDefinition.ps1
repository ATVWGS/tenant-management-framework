function Register-TmfRoleDefinition {
    Param (
        [bool] $present = $true,
        [Parameter(Mandatory = $true)]
        [string] $displayName,
        [Parameter(Mandatory = $true)]
        [string] $description,
        [Parameter(Mandatory = $true)]
        [string] $subscriptionReference,
        [Parameter(Mandatory = $true)]
        [string[]] $assignableScopes,
        [Parameter(Mandatory = $true)]
        [object[]] $permissions,
        [string] $sourceConfig = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin {
        $resourceName = "roleDefinitions"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

        if ($script:desiredConfiguration[$resourceName].displayName -contains $roleName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }		

		$object = [PSCustomObject] @{
			present = $present
			displayName = $displayName
			description = $description
            subscriptionReference = $subscriptionReference
			assignableScopes = $assignableScopes
            permissions = $permissions
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