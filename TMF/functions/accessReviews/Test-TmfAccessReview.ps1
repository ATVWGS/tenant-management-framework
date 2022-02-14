function Test-TmfAccessReview
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
		[string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "accessReviews"
		$tenant = Get-MgOrganization -Property displayName, Id
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
				ResourceType = 'AccessReview'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}
			
			try {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/accessReviews/definitions/?`$filter=displayName eq '{0}'" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName))).Value
			}
			catch {
				Write-PSFMessage -Level Warning -String 'TMF.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
				$exception = New-Object System.Data.DataException("Query with filter $filter against Microsoft Graph failed. Error: $_")
				$errorID = 'QueryWithFilterFailed'
				$category = [System.Management.Automation.ErrorCategory]::NotSpecified
				$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
				$cmdlet.ThrowTerminatingError($recordObject)
			}
			
			switch ($resource.Count) {
				0 {
					if ($definition.present) {					
						if ((Get-Date -Date ($definition.settings.recurrence.range.startDate)) -lt (Get-Date -Format "yyyy-MM-dd")) {
							Write-PSFMessage -Level Warning -String 'TMF.Error.StartDateValidationFailed' -StringValues $filter -Tag 'failed'
							$exception = New-Object System.Data.DataException("$($result.ResourceType) ($($result.ResourceName)) can not be created with parameter startDate in the past!")
							$errorID = "StartDateValidationFailed"
							$category = [System.Management.Automation.ErrorCategory]::NotSpecified
							$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
							$cmdlet.ThrowTerminatingError($recordObject)
						}
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
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "present"})) {
							$change = [PSCustomObject] @{
								Property = $property										
								Actions = $null
							}
							
							switch ($property) {
								"settings" {
									foreach ($item in ($definition.$property.GetEnumerator().Name | Where-Object {$_ -notin "applyActions","recurrence"})) {
										if (($definition.$property.$item -ne $resource.$property.$item) -and $definition.$property.$item.gettype()) {
											$change.Actions = @{"Set" = $definition.$property.$item}
										}
									}
									foreach ($item in $definition.$property.recurrence.pattern.GetEnumerator().Name) {
										if ($definition.$property.recurrence.pattern.$item -ne $resource.$property.recurrence.pattern.$item){
											$change.Actions = @{"Set" = $definition.$property.recurrence.pattern}
										}
									}
									foreach ($item in $definition.$property.recurrence.range.GetEnumerator().Name) {
										if ($definition.$property.recurrence.range.$item -ne $resource.$property.recurrence.range.$item){
											$change.Actions = @{"Set" = $definition.$property.recurrence.range}
										}
									}
								}
								"reviewers" {
									if (Compare-Object $definition.$property.query $resource.$property.query) {
										$change.Actions = @{"Set" = $definition.$property}
									}
								}
								"scope" {
									if ($definition.$property.query) {
										if ($resource.$property.query) {
											if (Compare-Object $definition.$property.query $resource.$property.query) {

												Write-PSFMessage -Level Warning -String 'TMF.Error.ScopeValidationFailed' -StringValues $filter -Tag 'failed'
												$exception = New-Object System.Data.DataException("$($result.ResourceType) ($($result.ResourceName)): Scope for existing access review can not be changed!")
												$errorID = "ScopeValidationFailed"
												$category = [System.Management.Automation.ErrorCategory]::NotSpecified
												$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
												$cmdlet.ThrowTerminatingError($recordObject)
											}
										}
										else {
											Write-PSFMessage -Level Warning -String 'TMF.Error.ScopeValidationFailed' -StringValues $filter -Tag 'failed'
											$exception = New-Object System.Data.DataException("$($result.ResourceType) ($($result.ResourceName)): Scope for existing access review can not be changed!")
											$errorID = "ScopeValidationFailed"
											$category = [System.Management.Automation.ErrorCategory]::NotSpecified
											$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
											$cmdlet.ThrowTerminatingError($recordObject)
										}
									}
									else {
										if ($definition.$property.principalScopes) {
											if (Compare-Object $definition.$property.principalScopes.query $resource.$property.principalScopes.query) {
												Write-PSFMessage -Level Warning -String 'TMF.Error.ScopeValidationFailed' -StringValues $filter -Tag 'failed'
												$exception = New-Object System.Data.DataException("$($result.ResourceType) ($($result.ResourceName)): Scope for existing access review can not be changed!")
												$errorID = "ScopeValidationFailed"
												$category = [System.Management.Automation.ErrorCategory]::NotSpecified
												$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
												$cmdlet.ThrowTerminatingError($recordObject)
											}
										}
									}
								}
							}

							if ($change.Actions) {$changes += $change}
                        }
						
						if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
						else { $result = New-TestResult @result -ActionType "NoActionRequired" }
                    }
					else {
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
