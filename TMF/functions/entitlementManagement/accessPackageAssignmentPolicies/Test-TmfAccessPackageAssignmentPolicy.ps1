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

				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies?`$filter=(displayname eq '{0}') and (accessPackageId eq '{1}')" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName), $accessPackageId)).Value

				if (("oldNames" -in $definition.Properties()) -and (-not($resource))) {
					foreach ($oldName in $definition.oldNames) {
						$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageAssignmentPolicies?`$filter=(displayname eq '{0}') and (accessPackageId eq '{1}')" -f [System.Web.HttpUtility]::UrlEncode($oldName), $accessPackageId)).Value
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
								{$_ -in "accessReviewSettings", "requestApprovalSettings", "requestorSettings"} {
									$needUpdate = $false
									foreach ($key in $definition.$property.Keys) {
										switch ($key) {
											"approvalStages" {
												"primaryApprovers", "escalationApprovers" | Where-Object { $_ -in $definition.$property.$key.Keys } | Foreach-Object {								
													if (Check-UserSetRequiresUpdate -Reference $resource.$property.$key.$_ -Difference $definition.$property.$key.$_ -Cmdlet $Cmdlet) {
														$needUpdate = $true
													}
												}
											}
											{$_ -in "reviewers", "allowedRequestors"} {
												if (Check-UserSetRequiresUpdate -Reference $resource.$property.$key -Difference $definition.$property.$key -Cmdlet $Cmdlet) {
													$needUpdate = $true
												}
											}
											default {
												if ($definition.$property[$key] -ne $resource.$property.$key) {
													$needUpdate = $true
												}
											}
										}
									}
									if ($needUpdate) { $change.Actions = @{"Set" = $definition.$property} }
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
