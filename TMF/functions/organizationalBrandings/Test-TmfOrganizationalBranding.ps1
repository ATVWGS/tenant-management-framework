function Test-TmfOrganizationalBranding {
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
		$resourceName = "OrganizationalBranding"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/organization?`$select=displayname,id")).value
	}
	process
	{
		$definitions = $script:desiredConfiguration[$resourceName]

		foreach ($definition in $definitions) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property) {
					if ($definition.$property.GetType().Name -eq "String") {
						$definition.$property = Resolve-String -Text $definition.$property
					}
				}
			}

            $result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'organizationalBranding'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
                $resource = @()
                if ($definition.displayName -eq "default") {
                    $id = 0
                }
                else {
                    $id = $definition.displayName
                }
                $resource += (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/organization/$($tenant.id)/branding/localizations")).Value | Where-Object {$_.id -eq $id}
				
			}
			catch {
				Write-PSFMessage -Level Warning -String 'TMF.Error.QueryWithFilterFailed' -StringValues "id eq '$($definition.displayName)'" -Tag 'failed'
				$exception = New-Object System.Data.DataException("Query with filter 'id eq $($definition.displayName)' against Microsoft Graph failed. Error: $_")
				$errorID = 'QueryWithFilterFailed'
				$category = [System.Management.Automation.ErrorCategory]::NotSpecified
				$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
				$cmdlet.ThrowTerminatingError($recordObject)
			}
			
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
						$changes = @()
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayname", "present", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property
								Actions = $null
							}

                            if ($definition.$property -ne $resource.$property) {
                                if ($definition.$property -like "" -and $resource.$property -like "") {
                                    #exclude null values in both configurations
                                }
                                else {
                                    $change.Actions = @{"Set" = $definition.$property};
                                }
                            }
							if ($change.Actions) {$changes += $change}
						}
	
						if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
						else { $result = New-TestResult @result -ActionType "NoActionRequired" }
					}
					else {
                        if ($definition.displayName -eq "default") {
                            Write-PSFMessage -Level Warning -String 'TMF.Test.DeleteNotPossible' -StringValues $resourceName, $definition.displayName
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
}
