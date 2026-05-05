function Test-TmfAdminConsentRequestPolicy {
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
		$resourceName = "adminConsentRequestPolicy"
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
				ResourceType = 'adminConsentRequestPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
                $resource = @()
				$resource += Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/policies/adminConsentRequestPolicy")
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
						if (-not ($definition.isEnabled) -and -not ($resource.isEnabled)) {
							$result = New-TestResult @result -ActionType "NoActionRequired"
						}
						else {
							$changes = @()
							foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig", "sourceFile", "displayName"})) {
								$change = [PSCustomObject] @{
									Property = $property										
									Actions = $null
								}

								switch ($property) {
									"reviewers" {
										if ($definition.$property.count -ne $resource.$property.count) {
											$change.Actions = @{"Set" = $definition.$property}
										}
										else {
											if (Compare-Object -ReferenceObject $definition.$property.query -DifferenceObject $resource.$property.query) {
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