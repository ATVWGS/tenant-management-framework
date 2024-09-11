function Register-TmfRoleManagementPolicy {
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string]$roleReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$subscriptionReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string]$scopeReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string]$groupReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string]$scopeType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string]$ruleTemplate,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
        [object[]]$activationApprover,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
		[string] $sourceConfig = "<Custom>",
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
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
            if ($groupReference) {
                $policyScope = "AADGroup"
            }
            else {
                $policyScope = "AzureAD"
            }            
        }

        switch ($policyScope) {
            "AzureAD"   {
                if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.scopeReference -eq $scopeReference}) {			
                    $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.scopeReference -eq $scopeReference}
                }
            }
            "AADGroup"   {
                if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.groupReference -eq $groupReference}) {			
                    $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.roleReference -eq $roleReference -and $_.groupReference -eq $groupReference}
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

            "AADGroup"   {
                $object = [PSCustomObject] @{
                    roleReference = $roleReference
                    scopeReference = $groupReference
                    scopeType = $scopeType
                    ruleTemplate = $ruleTemplate
                    sourceConfig = $sourceConfig
                    activationApprover = $activationApprover
                }
                if ($roleReference -notin @("member","owner")) {
                    Write-PSFMessage -Level Error -String 'TMF.Register.UnsupportedPropertyValue' -StringValues $roleReference, "member, owner" -Tag 'failed' -FunctionName $Cmdlet.CommandRuntime
			        $ErrorObject = New-Object Management.Automation.ErrorRecord "The provided value for property '$($roleReference)' is not supported. Possible values are: member, owner", "1", 'InvalidData', $object
                    $cmdlet.ThrowTerminatingError($ErrorObject)
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