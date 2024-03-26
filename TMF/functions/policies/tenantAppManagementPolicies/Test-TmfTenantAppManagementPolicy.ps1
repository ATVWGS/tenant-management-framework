function Test-TmfTenantAppManagementPolicy {
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
		$resourceName = "tenantAppManagementPolicy"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
        $definitions = $script:desiredConfiguration[$resourceName]

        if ($definitions.count -gt 1) {
            throw "Multiple definitions for $($resourceName) aren't possible, because only one $($resourceName) exists. Please reduce definitions to one single definition."
        }

		foreach ($definition in $definitions) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'tenantAppManagementPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
				$resource = @()
				$resource += Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/defaultAppManagementPolicy")
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
                1 {
                    $result["GraphResource"] = $resource
					if ($definition.present) {
						$changes = @()
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property										
								Actions = $null
							}

							switch ($property) {
                                "applicationRestrictions" {
                                    if (-not (Compare-AppManagementPolicyRestrictions -ReferenceObject ($definition.$property | Convertto-PSFHashtable) -DifferenceObject $resource.$property)) {
                                        $change.Actions = @{"Set" = $definition.$property}
                                    }
                                }
                                "servicePrincipalRestrictions" {
                                    if (-not (Compare-AppManagementPolicyRestrictions -ReferenceObject ($definition.$property | Convertto-PSFHashtable) -DifferenceObject $resource.$property)) {
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
                        throw "Deletion of $($resourceName) is not possible. Change property 'present' of $($resourceName) to 'true' and try again."
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

			$result
        }
    }

    end {}
}