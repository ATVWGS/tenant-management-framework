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
		[string[]] $SourceFile,
		[string[]] $SourceConfig,
		[switch] $RawOutput,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "accessReviews"
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
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "present", "sourceFile", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property										
								Actions = $null
							}
							
							switch ($property) {
								"settings" {
									foreach ($item in ($definition.$property.GetEnumerator().Name | Where-Object {$_ -notin "applyActions","recurrence","recommendationInsightSettings"})) {
										if (($definition.$property.$item -ne $resource.$property.$item) -and $definition.$property.$item.gettype()) {
											$change.Actions = @{"Set" = $definition.$property.$item}
										}
									}
									if ($definition.$property.recommendationInsightSettings.recommendationLookBackDuration -and $resource.$property.recommendationInsightSettings.recommendationLookBackDuration) {
										if ($definition.$property.recommendationInsightSettings.recommendationLookBackDuration -ne $resource.$property.recommendationInsightSettings.recommendationLookBackDuration) {
											Write-PSFMessage -Level Warning -String 'TMF.Test.UpdateNotPossibleForParameter' -StringValues "recommendationLookBackDuration",$resourceName
										}
									}									
									if ($definition.$property.recurrence.pattern -and $resource.$property.recurrence.pattern) {
										foreach ($item in $definition.$property.recurrence.pattern.GetEnumerator().Name) {
											if ($definition.$property.recurrence.pattern.$item -ne $resource.$property.recurrence.pattern.$item){
												$change.Actions = @{"Set" = $definition.$property.recurrence.pattern}
											}
										}
									}
									else {
										if (($definition.$property.recurrence.pattern -and (-not $resource.$property.recurrence.pattern)) -or ((-not $definition.$property.recurrence.pattern) -and $resource.$property.recurrence.pattern)) {
											$change.Actions = @{"Set" = $definition.$property.recurrence.pattern}
										}
									}
									
									foreach ($item in $definition.$property.recurrence.range.GetEnumerator().Name) {
										if ($definition.$property.recurrence.range.$item -ne $resource.$property.recurrence.range.$item){
											if ($null -eq $resource.$property.recurrence.range.$item -and $definition.$property.recurrence.range.$item -like "" ) {
												#No change
											}
											else {
												$change.Actions = @{"Set" = $definition.$property.recurrence.range}
											}											
										}
									}
								}
								{@("reviewers", "fallbackReviewers") -contains $_} {
									if ($definition.$property -and $resource.$property) {
										if (Compare-Object $definition.$property.query $resource.$property.query) {
											$change.Actions = @{"Set" = $definition.$property}
										}
									}
									else {
										if (($definition.$property -and (-not $resource.$property)) -or ((-not $definition.$property) -and $resource.$property)) {
											$change.Actions = @{"Set" = $definition.$property}
										}
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
			
			if ($RawOutput) {
				$result
			}
			else {
				$result | Beautify-TmfTestResult
			}
		}
	}
}
