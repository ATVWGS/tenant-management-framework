﻿function Test-TmfAgreement
{
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "agreements"
		$tenant = Get-MgOrganization -Property displayName, Id		
	}
	process
	{
		$results = @()
		foreach ($definition in $script:desiredConfiguration[$resourceName]) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'Agreement'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/identityGovernance/termsOfUse/agreements/?`$filter=displayName eq '{0}'" -f $definition.displayName)).Value
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
						foreach ($property in ($definition.Properties() | ? {$_ -notin "displayName", "present", "sourceConfig"})) {
							$change = [PSCustomObject] @{
								Property = $property										
								Actions = $null
							}
							switch ($property) {
								"termsExpiration" {
									<# Currently not supported! if (
										((Get-Date $definition.termsExpiration.startDateTime) -ne (Get-Date $resource.termsExpiration.startDateTime)) -or
										$definition.termsExpiration.startDateTime -ne $resource.termsExpiration.startDateTime
									)
									{
										$change.Actions = @{"Set" = $definition.$property}
									}#>
								}
								"files" { <# Currently not supported! #> }
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