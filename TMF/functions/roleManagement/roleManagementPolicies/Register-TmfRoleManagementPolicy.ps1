function Register-TmfRoleManagementPolicy {
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$roleReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$subscriptionReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$scopeReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$scopeType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$ruleTemplate,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [object[]]$activationApprover,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
		[string] $sourceConfig = "<Custom>",
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin {
        $resourceName = "roleManagementPolicies"
        if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}
        if ($subscriptionReference) {
            $policyScope = "AzureResources"
        }
        else {
            $policyScope = "AzureAD"
        }

        switch ($policyScope) {
            "AzureAD"   {
                if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.scopeReference -eq $scopeReference}) {			
                    $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.scopeReference -eq $scopeReference}
                }
            }

            "AzureResources" {
                if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.subscriptionReference -eq $subscriptionReference -and $_.scopeReference -eq $scopeReference}) {			
                    $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.subscriptionReference -eq $subscriptionReference -and $_.scopeReference -eq $scopeReference}
                }
            }
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) {return}

        switch ($policyScope) {
            "AzureAD"   {
                $object = [PSCustomObject] @{
                    roleReference = $roleReference
                    scopeReference = $scopeReference
                    scopeType = $scopeType
                    ruleTemplate = $ruleTemplate
                    sourceConfig = $sourceConfig
                    activationApprover = $activationApprover
                }
            }

            "AzureResources" {
                $object = [PSCustomObject] @{
                    roleReference = $roleReference
                    subscriptionReference = $subscriptionReference
                    scopeReference = $scopeReference
                    scopeType = $scopeType
                    ruleTemplate = $ruleTemplate
                    sourceConfig = $sourceConfig
                    activationApprover = $activationApprover
                }
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

    end {

    }
}