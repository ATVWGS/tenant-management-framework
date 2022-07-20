function Register-TmfRoleManagementPolicyRuleTemplate {
    Param (
        [Parameter(Mandatory = $true)]
        [string] $displayName,
        [Parameter(Mandatory = $true)]
        [object[]] $rules,
        [System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin {
        $resourceName = "roleManagementPolicyRuleTemplates"
        if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

        if ($script:desiredConfiguration[$resourceName].displayName -contains $displayname) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }		

		$object = [PSCustomObject] @{
			displayName = $displayName
			rules = $rules
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