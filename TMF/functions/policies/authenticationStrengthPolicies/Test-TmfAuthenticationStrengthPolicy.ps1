function Test-TmfAuthenticationStrengthPolicy {
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
		$resourceName = "authenticationStrengthPolicies"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
		foreach ($definition in $script:desiredConfiguration[$resourceName]) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'authenticationStrengthPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
                $resource = @()
				$resource += (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationStrengthPolicies?`$filter=displayname eq '{0}'" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName))).value
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
					if ($definition.present) {
                        if ($resource.policyType -eq "builtIn") {
                            Write-PSFMessage -Level Error -String 'TMF.Test.UpdateNotPossibleForBuiltInResources' -StringValues "authenticationStrengthPolicies",$definition.displayName -Tag "failed"
                            $exception = New-Object System.Data.DataException("Trying to update built-in authenticationStrengthPolicy.")
					        $errorID = 'DeleteBuiltInResourceError'
					        $category = [System.Management.Automation.ErrorCategory]::NotSpecified
					        $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
			                $cmdlet.ThrowTerminatingError($recordObject)
                        }
						$changes = @()
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property										
								Actions = $null
							}

							if ($property -eq "allowedCombinations") {
                                if (Compare-Object -ReferenceObject $definition.$property -DifferenceObject $resource.$property) {
                                    $change.Actions = @{"Set" = $definition.$property}
                                }
							}
							else {
								if ($definition.$property -ne $resource.$property) {
									$change.Actions = @{"Set" = $definition.$property}
								}
							}
							if ($change.Actions) {$changes += $change}
						}
	
						if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
						else { $result = New-TestResult @result -ActionType "NoActionRequired" }
					}
					else {
                        if ($resource.policyType -eq "builtIn") {
                            Write-PSFMessage -Level Error -String 'TMF.Test.DeleteNotPossibleForBuiltInResources' -StringValues "authenticationStrengthPolicies",$definition.displayName -Tag "failed"
                            $exception = New-Object System.Data.DataException("Trying to delete built-in authenticationStrengthPolicy.")
					        $errorID = 'DeleteBuiltInResourceError'
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
            $result            
        }
    }
    
    end {}
}