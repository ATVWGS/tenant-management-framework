function Test-TmfAccessPackageAssignmentPolicy
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
		$resourceName = "accessPackageAssignmentPolicies"
		$tenant = Get-MgOrganization -Property displayName, Id
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
				ResourceType = 'AccessPackageAssignmentPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			$accessPackageId = $definition.accessPackageId()
			if (-Not $accessPackageId) {
				Write-PSFMessage -Level Host -String 'TMF.RelatedResourceDoesNotExist' -StringValues "Access Package", $accessPackage, $result.ResourceType, $result.ResourceName
				New-TestResult @result -ActionType "Create"				
				continue
			}

			try {			

				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/identityGovernance/entitlementManagement/assignmentPolicies?`$expand=accessPackage&`$filter=(displayname eq '{0}') and (accessPackage/id eq '{1}')" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName), $accessPackageId)).Value

				if (("oldNames" -in $definition.Properties()) -and (-not($resource))) {
					foreach ($oldName in $definition.oldNames) {
						$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/identityGovernance/entitlementManagement/assignmentPolicies?`$expand=accessPackage&`$filter=(displayname eq '{0}') and (accessPackage/id eq '{1}')" -f [System.Web.HttpUtility]::UrlEncode($oldName), $accessPackageId)).Value
						if ($resource) {break}
					}
				}
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
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig", "accessPackage", "oldNames"})) {
							$change = [PSCustomObject] @{
								Property = $property										
								Actions = $null
							}

							switch ($property) {
								{$_ -in "reviewSettings", "requestApprovalSettings", "requestorSettings", "expiration", "automaticRequestSettings"} {
									$needUpdate = $false
									foreach ($key in $definition.$property.Keys) {
										switch ($key) {
											"stages" {
												if ($definition.$property.$key.count -ne $resource.$property.$key.count) {
													$needUpdate = $true
												}
												else {
													for ($i=0;$i -lt $definition.$property.$key.count;$i++) {
														"primaryApprovers", "escalationApprovers", "fallbackPrimaryApprovers", "fallbackEscalationApprovers" | Where-Object { $_ -in $definition.$property.$key[$i].Keys } | Foreach-Object {								
															if (Check-SubjectSetRequiresUpdate -Reference $resource.$property.$key[$i].$_ -Difference $definition.$property.$key[$i].$_ -Cmdlet $Cmdlet) {
																$needUpdate = $true
															}
														}
														"durationBeforeAutomaticDenial", "isApproverJustificationRequired", "isEscalationEnabled", "durationBeforeEscalation" | Where-Object { $_ -in $definition.$property.$key[$i].Keys } | Foreach-Object {
															if ($definition.$property.$key[$i].$_ -ne $resource.$property.$key[$i].$_) {
																$needUpdate = $true
															}
														}
													}
												}
											}
											"schedule" {
												foreach ($item in $definition.$property.$key.recurrence.pattern.GetEnumerator().Name) {
													if ($definition.$property.$key.recurrence.pattern.$item -ne $resource.$property.$key.recurrence.pattern.$item){
														$change.Actions = @{"Set" = $definition.$property.$key.recurrence.pattern}
													}
												}
												foreach ($item in $definition.$property.$key.recurrence.range.GetEnumerator().Name) {
													if ($definition.$property.$key.recurrence.range.$item -ne $resource.$property.$key.recurrence.range.$item){
														$change.Actions = @{"Set" = $definition.$property.$key.recurrence.range}
													}
												}
												foreach ($item in $definition.$property.$key.expiration.GetEnumerator().Name) {
													switch ($item) {
														"endDateTime" {
															if ($definition.$property.$key.$item) {
																if (([datetime]$definition.$property.$key.$item).ToUniversalTime().ToString() -ne $resource.$property.$key.$item.toString()) {
																	$change.Actions = @{"Set" = $definition.$property.$key.$item}
																}
															}															
														}
														default {
															if ($definition.$property.$key.$item -ne $resource.$property.$key.$item) {
																$change.Actions = @{"Set" = $definition.$property.$key.$item}
															}
														}
													}
												}
											}
											{$_ -in "primaryReviewers", "fallbackReviewers", "onBehalfRequestors"} {
												if (Check-SubjectSetRequiresUpdate -Reference $resource.$property.$key -Difference $definition.$property.$key -Cmdlet $Cmdlet) {
													$needUpdate = $true
												}
											}
											default {
												if ($key -eq "endDateTime") {
													if ($definition.$property.$key) {
														if (([datetime]$definition.$property.$key).touniversaltime().tostring() -ne $resource.$property.$key.tostring()) {
															$needUpdate = $true
														}
													}
												}
												else {
													if ($definition.$property.$key -ne $resource.$property.$key) {
														$needUpdate = $true
													}
												}
											}
										}
									}
									if ($needUpdate) { $change.Actions = @{"Set" = $definition.$property} }
								}
								"specificAllowedTargets" {
									if (Check-SubjectSetRequiresUpdate -Reference $resource.$property -Difference $definition.$property -Cmdlet $Cmdlet) {
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
