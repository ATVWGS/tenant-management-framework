function Test-TmfDeviceRegistrationPolicy {
    <#
		.SYNOPSIS
			Test desired configuration against a Tenant.
		.DESCRIPTION
			Compare current configuration of a resource type with the desired configuration.
			Return a result object with the required changes and actions.
	#>
	[CmdletBinding()]
	Param (
		[switch] $RawOutput,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "deviceRegistrationPolicy"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/organization?`$select=displayname,id")).value
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
				ResourceType = 'deviceRegistrationPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
                $resource = @()
				$resource += Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/policies/deviceRegistrationPolicy")
			}
			catch {
				Write-PSFMessage -Level Warning -String 'TMF.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
				$exception = New-Object System.Data.DataException("Query with filter $filter against Microsoft Graph failed. Error: $_")
				$errorID = 'QueryWithFilterFailed'
				$category = [System.Management.Automation.ErrorCategory]::NotSpecified
				$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
				$cmdlet.ThrowTerminatingError($recordObject)
			}

            $result["GraphResource"] = $resource
            $changes = @()

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
					if ($definition.present) {
						
                        $changes = @()
                        foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig", "sourceFile", "displayName"})) {
                            $change = [PSCustomObject] @{
                                Property = $property										
                                Actions = $null
                            }

                            switch ($property) {
                                "azureADJoin" {
                                    $changed = $false
                                    "isAdminConfigurable","localAdmins","allowedToJoin" | ForEach-Object {
                                        switch ($_) {
                                            "isAdminConfigurable" {
                                                if ($definition.$property.$_ -ne $resource.$property.$_) {
                                                    $changed = $true
                                                }
                                            }
                                            "localAdmins" {
                                                if ($definition.$property.localAdmins.enableGlobalAdmins -ne $resource.$property.localAdmins.enableGlobalAdmins) {
                                                    $changed = $true
                                                }
                                                if ($definition.$property.localAdmins.registeringUsers."@odata.type" -ne $definition.$property.localAdmins.registeringUsers."@odata.type") {
                                                    $changed = $true
                                                }
                                                if ($definition.$property.localAdmins.registeringUsers."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership" -and $definition.$property.localAdmins.registeringUsers."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {

                                                    if (Compare-Object $definition.$property.localAdmins.registeringUsers.users $resource.$property.localAdmins.registeringUsers.users) {
                                                        $changed = $true
                                                    }
                                                    if (Compare-Object $definition.$property.localAdmins.registeringUsers.groups $resource.$property.localAdmins.registeringUsers.groups) {
                                                        $changed = $true
                                                    }
                                                }
                                            }
                                            "allowedToJoin" {
                                                if ($definition.$property.allowedToJoin."@odata.type" -ne $definition.$property.allowedToJoin."@odata.type") {
                                                    $changed = $true
                                                }
                                                if ($definition.$property.allowedToJoin."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership" -and $definition.$property.allowedToJoin."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {

                                                    if (Compare-Object $definition.$property.allowedToJoin.users $resource.$property.allowedToJoin.users) {
                                                        $changed = $true
                                                    }
                                                    if (Compare-Object $definition.$property.allowedToJoin.groups $resource.$property.allowedToJoin.groups) {
                                                        $changed = $true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if ($changed) {
                                        $change.Actions = @{"Set" = $definition.$property}
                                    }
                                }
                                "azureADRegistration" {
                                    if ($definition.$property.isAdminConfigurable -ne $resource.$property.isAdminConfigurable) {
                                        $change.Actions = @{"Set" = $definition.$property}
                                    }
                                    if ($definition.$property.allowedToRegister."@odata.type" -ne $resource.$property.allowedToRegister."@odata.type") {
                                        $change.Actions = @{"Set" = $definition.$property}
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
						Write-PSFMessage -Level Warning -String 'TMF.Invoke.DeleteNotPossible' -StringValues $result.ResourceType, $result.ResourceName
						$result = New-TestResult @result -ActionType "NoActionRequired"
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

			if ($RawOutput) {
				$result
			}
			else {
				$result | Beautify-TmfTestResult
			}
        }
    }

    end {}
}