function Register-TmfRoleDefinition {
    [CmdletBinding(DefaultParameterSetName = 'AzureAD')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [bool] $present,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $displayName,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $description,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $subscriptionReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string[]] $assignableScopes,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [object[]] $permissions,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [object[]] $rolePermissions,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [string] $sourceConfig = "<Custom>",
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
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
        if ($subscriptionReference) {
            $roleDefinitionScope = "AzureResources"
        }
        else {
            $roleDefinitionScope = "AzureAD"
        }
    }

    process {
        if (Test-PSFFunctionInterrupt) { return }		

        switch ($roleDefinitionScope) {
            "AzureAD" {
                $object = [PSCustomObject] @{
                    present = $present
                    displayName = $displayName
                    description = $description
                    rolePermissions = $rolePermissions
                    sourceConfig = $sourceConfig
                }
            }
            "AzureResources" {
                $object = [PSCustomObject] @{
                    present = $present
                    displayName = $displayName
                    description = $description
                    subscriptionReference = $subscriptionReference
                    assignableScopes = $assignableScopes
                    permissions = $permissions
                    sourceConfig = $sourceConfig
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

    end {}
}