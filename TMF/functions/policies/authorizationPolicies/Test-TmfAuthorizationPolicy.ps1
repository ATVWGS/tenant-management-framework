function Test-TmfAuthorizationPolicy {
    <#
		.SYNOPSIS
			Test desired configuration against a Tenant.
		.DESCRIPTION
			Compare current configuration of a resource type with the desired configuration.
			Return a result object with the required changes and actions.
	#>
	[CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
		[string[]] $SourceFile,
		[string[]] $SourceConfig,
        [switch] $RawOutput,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "authorizationPolicies"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value

		if (($SpecificResources -and $SourceFile -and $SourceConfig) -or ($SpecificResources -and $SourceFile) -or ($SourceFile -and $SourceConfig)) {
			$exception = New-Object System.Data.DataException("Multiple filters are not supported. You can only filter by one type, sourceFile or sourceConfig or specificResources!")
			$errorID = "MultipleFiltersNotSupported"
			$category = [System.Management.Automation.ErrorCategory]::NotSpecified
			$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
			$cmdlet.ThrowTerminatingError($recordObject)
		}
	}
	process
	{

		$definitions = @()
		if ($SpecificResources) {
			foreach ($specificResource in $SpecificResources) {

				if ($specificResource -match "\*") {
					if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -like $specificResource}) {
						$definitions += $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -like $specificResource}
					}
					else {
						Write-PSFMessage -Level Warning -String 'TMF.Error.SpecificResourceNotExists' -StringValues $filter -Tag 'failed'
						$exception = New-Object System.Data.DataException("$($specificResource) not exists in Desired Configuration for $($resourceName)!")
						$errorID = "SpecificResourceNotExists"
						$category = [System.Management.Automation.ErrorCategory]::NotSpecified
						$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
						$cmdlet.ThrowTerminatingError($recordObject)
					}
				}
				else {
					if ($script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $specificResource}) {
						$definitions += $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $specificResource}
					}
					else {
						Write-PSFMessage -Level Warning -String 'TMF.Error.SpecificResourceNotExists' -StringValues $filter -Tag 'failed'
						$exception = New-Object System.Data.DataException("$($specificResource) not exists in Desired Configuration for $($resourceName)!")
						$errorID = "SpecificResourceNotExists"
						$category = [System.Management.Automation.ErrorCategory]::NotSpecified
						$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
						$cmdlet.ThrowTerminatingError($recordObject)
					}
				}
			}
			$definitions = $definitions | Sort-Object -Property displayName -Unique
		}
		elseif ($SourceFile) {
			foreach ($file in $SourceFile) {
				$definitions += $script:desiredConfiguration[$resourceName] | Where-Object {$_.sourceFile -eq $file}
			}
		}
		elseif ($SourceConfig) {
			foreach ($config in $SourceConfig) {
				$definitions += $script:desiredConfiguration[$resourceName] | Where-Object {$_.sourceConfig -eq $config}
			}					
		}
		else {
			$definitions = $script:desiredConfiguration[$resourceName]
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
				ResourceType = 'authorizationPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
				$resource = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authorizationPolicy/authorizationPolicy")
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

            foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "sourceConfig", "sourceFile"})) {
                $change = [PSCustomObject] @{
                    Property = $property										
                    Actions = $null
                }

                switch ($property) {
                    "defaultUserRolePermissions" {
                        foreach ($item in $definition.$property.GetEnumerator().Name) {

                            if ($definition.$property.$item -ne $resource.$property.$item) {
                                $change.Actions = @{"Set" = $definition.$property.$item}
                            }
                        }
                    }
                    "permissionGrantPolicyIdsAssignedToDefaultUserRole" {
                        if ($definition.$property -and $resource.$property) {
                            if (Compare-Object $definition.$property $resource.$property) {
                                $change.Actions = @{"Set" = $definition.$property}
                            }
                        }
                        else {
                            if ($definition.$property -or $resource.$property) {
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