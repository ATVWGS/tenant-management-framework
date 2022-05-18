function Test-TmfRoleDefinition 
{
    <#
		.SYNOPSIS
			Test desired configuration against a Tenant.
		.DESCRIPTION
			Compare current configuration of a resource type with the desired configuration.
			Return a result object with the required changes and actions.
	#>
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

    begin
	{
        Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "roleDefinitions"
        $tenant = Get-MgOrganization -Property displayName, Id
	}
	process 
    {
        $definitions = $script:desiredConfiguration[$resourceName]

		foreach ($definition in $definitions) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'roleDefinition'
                ResourceName = $definition.displayName
				DesiredConfiguration = $definition
			}

            if ($definition.subscriptionReference) {
                $roleDefinitionScope = "AzureResources"
                Test-AzureConnection -Cmdlet $Cmdlet
                $token = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
            }
            else {
                $roleDefinitionScope = "AzureAD"
            }

            switch ($roleDefinitionScope) {
                "AzureResources" {
                    foreach ($entry in $definition.assignableScopes) {
                        switch (($entry.ToCharArray() | Where-Object {$_ -eq '/'}).count) {
                            2 {Get-AzSubscription -SubscriptionId $entry.Split("/")[-1] | Out-Null}
                            4 {Get-AzResourceGroup -Name $entry.split("/")[-1] | Out-Null}
                            6 {Get-AzResource -Name $entry.split("/")[-1] | Out-Null}
                            default {
                                Write-PSFMessage -Level Warning -String 'TMF.Test.RelatedResourceResolveError' -StringValues "assignableScope", $result.ResourceType, $result.ResourceName  -Tag 'failed'
                                $exception = New-Object System.Data.DataException("Cannot resolve assignableScope $($entry)")
                                $errorID = 'RelatedResourceResolveError'
                                $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                                $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                                $cmdlet.ThrowTerminatingError($recordObject)
                            }
                        }
                    }
        
                    $subscriptionId = Resolve-Subscription -InputReference $definition.subscriptionReference
                    $resource = (Invoke-RestMethod -Method GET -Uri "$($script:apiBaseUrl)$($subscriptionId.trimStart("/"))/providers/Microsoft.Authorization/roleDefinitions?api-version=2018-01-01-preview&`$filter=roleName eq '$($definition.displayName)'" -Headers @{"Authorization"="Bearer $($token)"}).value
        
                    switch ($resource.count) {
                        0 {
                            if ($definition.present) {					
                                $result = New-TestResult @result -ActionType "Create"
                            }
                            else {					
                                $result = New-TestResult @result -ActionType "NoActionRequired"
                            }
                        }
        
                        1 {
                            $result["GraphResource"] = $resource
        
                            if ($resource.properties.type -eq "BuiltInRole") {
                                Write-PSFMessage -Level Warning -String 'TMF.Test.BuiltInRoleDetected' -StringValues $definition.displayName -Tag 'failed'
                                $exception = New-Object System.Data.DataException("BuiltInRole detected.")
                                $errorID = 'BuiltInRoleDetected'
                                $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                                $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                                $cmdlet.ThrowTerminatingError($recordObject)
                            }
        
                            if ($definition.present) {
                                $changes = @()
                                foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayname","present","subscriptionReference","sourceConfig"})) {
                                    $change = [PSCustomObject] @{
                                        Property = $property										
                                        Actions = $null
                                    }
        
                                    switch ($property) {
                                        "permissions" {
                                            foreach ($item in ($definition.permissions | Get-Member -Type "NoteProperty").Name) {
                                                if ($definition.permissions.$item -and $resource.properties.permissions.$item) {
                                                    if (Compare-Object -ReferenceObject $definition.permissions.$item -DifferenceObject $resource.properties.permissions.$item) {
                                                        $change.Actions = @{"Set" = $definition.$property}
                                                    }
                                                }
                                                if (($definition.permissions.$item -and (-not ($resource.properties.permissions.$item))) -or ((-not ($definition.permissions.$item)) -and ($resource.properties.permissions.$item))) {
                                                    $change.Actions = @{"Set" = $definition.$property}
                                                }
                                            }
                                        }
                                        "assignableScopes" {
                                            if (Compare-Object -ReferenceObject $definition.$property -DifferenceObject $resource.properties.$property) {
                                                $change.Actions = @{"Set" = $definition.$property}
                                            }
                                        }
                                        default {
                                            if ($definition.$property -ne $resource.properties.$property) {
                                                $change.Actions = @{"Set" = $definition.$property}
                                            }
                                        }
                                    }
        
                                    if ($change.Actions) {$changes += $change}
                                }
        
                                if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
                                else { $result = New-TestResult @result -ActionType "NoActionRequired" }
                            }
                            else {
                                if ($resource.properties.type -eq "BuiltInRole") {
                                    Write-PSFMessage -Level Warning -String 'TMF.Test.BuiltInRoleDetected' -StringValues $definition.displayName -Tag 'failed'
                                    $exception = New-Object System.Data.DataException("BuiltInRole detected.")
                                    $errorID = 'BuiltInRoleDetected'
                                    $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                                    $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                                    $cmdlet.ThrowTerminatingError($recordObject)
                                }
                                $result = New-TestResult @result -ActionType "Delete"
                            }
                        }
                        default {
                            Write-PSFMessage -Level Warning -String 'TMF.Test.MultipleResourcesError' -StringValues $resourceName, $definition.displayName -Tag 'failed'
                            $exception = New-Object System.Data.DataException("Query returned multiple results. Cannot decide which resource to test.")
                            $errorID = 'MultipleResourcesError'
                            $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                            $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                            $cmdlet.ThrowTerminatingError($recordObject)
                        }
                    }
                }
                "AzureAD" {
                    $resource = (Invoke-MgGraphRequest -Method GET -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleDefinitions?`$filter=displayName eq '$($definition.displayname)'").value

                    switch ($resource.Count) {
                        0 {
                            if ($definition.present) {
                                $result = New-TestResult @result -ActionType "Create"
                            }
                            else {
                                $result = New-TestResult @result -ActionType "NoActionRequired"
                            }
                        }

                        1 {
                            $result["GraphResource"] = $resource

                            if ($resource.isBuiltIn) {
                                Write-PSFMessage -Level Warning -String 'TMF.Test.BuiltInRoleDetected' -StringValues $definition.displayName -Tag 'failed'
                                $exception = New-Object System.Data.DataException("BuiltInRole detected.")
                                $errorID = 'BuiltInRoleDetected'
                                $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                                $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                                $cmdlet.ThrowTerminatingError($recordObject)
                            }

                            if ($definition.present) {
                                $changes = @()
                                foreach ($property in ($definition.Properties() | Where-Object {$_ -in "description","rolePermissions"})) {
                                    $change = [PSCustomObject] @{
                                        Property = $property										
                                        Actions = $null
                                    }
        
                                    switch ($property) {
                                        "rolePermissions" {
                                            foreach ($item in ($definition.rolePermissions | Get-Member -Type "NoteProperty").Name) {
                                                if ($definition.rolePermissions.$item -and $resource.rolePermissions.$item) {
                                                    if (Compare-Object -ReferenceObject $definition.rolePermissions.$item -DifferenceObject $resource.rolePermissions.$item) {
                                                        $change.Actions = @{"Set" = $definition.$property}
                                                    }
                                                }
                                                if (($definition.rolePermissions.$item -and (-not ($resource.rolePermissions.$item))) -or ((-not ($definition.rolePermissions.$item)) -and ($resource.rolePermissions.$item))) {
                                                    $change.Actions = @{"Set" = $definition.$property}
                                                }
                                            }
                                        }
                                        default {
                                            if ($definition.$property -ne $resource.$property) {
                                                $change.Actions = @{"Set" = $definition.$property}
                                            }
                                        }
                                    }
                                    if ($change.Actions) {$changes += $change}
                                }
                                if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
                                else { $result = New-TestResult @result -ActionType "NoActionRequired" }
                            }
                            else {
                                if ($resource.isBuiltIn) {
                                    Write-PSFMessage -Level Warning -String 'TMF.Test.BuiltInRoleDetected' -StringValues $definition.displayName -Tag 'failed'
                                    $exception = New-Object System.Data.DataException("BuiltInRole detected.")
                                    $errorID = 'BuiltInRoleDetected'
                                    $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                                    $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                                    $cmdlet.ThrowTerminatingError($recordObject)
                                }
                                $result = New-TestResult @result -ActionType "Delete"
                            }
                        }

                        default {
                            Write-PSFMessage -Level Warning -String 'Tmf.Test.MultipleResourcesError' -StringValues $resourceName, $definition.displayName -Tag 'failed'
                            $exception = New-Object System.Data.DataException("Query returned multiple results. Cannot decide which resource to test.")
                            $errorID = 'MultipleResourcesError'
                            $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                            $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                            $cmdlet.ThrowTerminatingError($recordObject)
                        }
                    }
                }
            }
            
            $result
        }
    }
}