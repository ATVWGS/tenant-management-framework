function Test-TmfAdministrativeUnit
{
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
		$resourceName = "administrativeUnits"
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
				ResourceType = 'administrativeUnits'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			if ("oldNames" -in $definition.Properties()) {				
				$filter = ($definition.oldNames + $definition.displayName | Foreach-Object {
					"(displayName eq '{0}')" -f [System.Web.HttpUtility]::UrlEncode($_)
				}) -join " or "
			}
			else {
				$filter = "(displayName eq '{0}')" -f [System.Web.HttpUtility]::UrlEncode($definition.displayName)
			}
			try {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/?`$filter={0}" -f $filter)).Value			
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
						foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "oldNames", "present", "sourceConfig", "sourceFile"})) {
							$change = [PSCustomObject] @{
								Property = $property
								Actions = $null
							}
							switch ($property) {
								"users" {
									$resourceUsers = @()
									$userResponse = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/members/$/microsoft.graph.user" -f $resource.Id)
									if ($userResponse.Keys -contains "@odata.nextLink") {
										$resourceUsers += $userResponse.Value.Id
										while ($null -ne $userResponse."@odata.nextLink") {
											$userResponse = Invoke-MgGraphRequest -Method GET -Uri $userResponse."@odata.nextLink"
											$resourceUsers += $userResponse.Value.Id											
										}										
									}
									else {
										$resourceUsers += $userResponse.Value.Id
									}
									$change.Actions = Compare-ResourceList -ReferenceList $resourceUsers `
														-DifferenceList $($definition.users | ForEach-Object {Resolve-User -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"groups" {
									$resourceGroups = @()
									$groupResponse = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/members/$/microsoft.graph.group" -f $resource.Id)
									if ($groupResponse.Keys -contains "@odata.nextLink") {
										$resourceGroups += $groupResponse.Value.Id
										while ($null -ne $groupResponse."@odata.nextLink") {
											$groupResponse = Invoke-MgGraphRequest -Method GET -Uri $groupResponse."@odata.nextLink"
											$resourceGroups += $groupResponse.Value.Id											
										}
										
									}
									else {
										$resourceGroups += $groupResponse.Value.Id
									}
									$change.Actions = Compare-ResourceList -ReferenceList $resourceGroups `
														-DifferenceList $($definition.groups | ForEach-Object {Resolve-Group -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"devices" {
									$resourceDevices = @()
									$deviceResponse = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/members/$/microsoft.graph.device" -f $resource.Id)
									if ($deviceResponse.Keys -contains "@odata.nextLink") {
										$resourceDevices += $deviceResponse.Value.Id
										while ($deviceResponse."@odata.nextLink") {
											$deviceResponse = Invoke-MgGraphRequest -Method GET -Uri $deviceResponse."@odata.nextLink"
											$resourceDevices += $deviceResponse.Value.Id											
										}										
									}
									else {
										$resourceDevices += $deviceResponse.Value.Id
									}
									$change.Actions = Compare-ResourceList -ReferenceList $resourceDevices `
														-DifferenceList $($definition.devices | ForEach-Object {Resolve-Device -InputReference $_ -Cmdlet $Cmdlet}) `
														-Cmdlet $PSCmdlet
								}
								"scopedRoleMembers" {
									$resourceScopedRoleMembers = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers" -f $resource.Id)).Value `
																| Select-Object @{n = "identity"; e = { $_["roleMemberInfo"]["id"] }}, @{n = "role"; e = { $_["roleId"] }}, @{n = "id"; e = { $_["id"] }}

									$definitionScopedRoleMembers = @()
									$definition.scopedRoleMembers | Foreach-Object {
										$identityId = Resolve-User -InputReference $_.identity -Cmdlet $Cmdlet -DontFailIfNotExisting
										if (-Not $identityId -or $identityId -eq $_.identity) {
											$identityId = Resolve-Group -InputReference $_.identity -Cmdlet $Cmdlet -DontFailIfNotExisting
											if (-Not $identityId -or $identityId -eq $_.identity) {
												$identityId = Resolve-ServicePrincipal -InputReference $_.identity -Cmdlet $Cmdlet -DontFailIfNotExisting
												if (-Not $identityId -or $identityId -eq $_.identity) {
													$identityId = Resolve-Application -InputReference $_.identity -ReturnObjectId -DontFailIfNotExisting -Cmdlet $Cmdlet
													if (-Not $identityId -or $identityId -eq $_.identity) {
														$Cmdlet.ThrowTerminatingError("Cannot resolve $($_.identity) as user, group, application or serviceprincipal")
													}
												}
											}
										}
										$definitionScopedRoleMembers += [PSCustomObject]@{
											identity = $identityId
											role = Resolve-DirectoryRole -InputReference $_.role -Cmdlet $Cmdlet
										}
									}									

									$dummy = Compare-ResourceList -ReferenceList ($resourceScopedRoleMembers | Select-Object role, identity | Foreach-Object {$_ | ConvertTo-Json -Compress}) `
														-DifferenceList ($definitionScopedRoleMembers | Select-Object role, identity | Foreach-Object {$_ | ConvertTo-Json -Compress}) `
														-Cmdlet $PSCmdlet

									if ($dummy.Keys.count -gt 0) {
										$change.Actions = @{}
										if ($dummy.Keys -contains "Add") { 
											$change.Actions["Add"] = ($dummy["Add"] | Foreach-Object { $_ | ConvertFrom-Json })
										}
										if ($dummy.Keys -contains "Remove") {
											$change.Actions["Remove"] = @()
											foreach ($toRemove in ($dummy["Remove"] | Foreach-Object {$_ | ConvertFrom-Json})) {											
												$change.Actions["Remove"] += ($resourceScopedRoleMembers | Where-Object {$_.role -eq $toRemove.role -and $_.identity -eq $toRemove.identity}).id
											}
										}								
									}							
								}
								{$_ -in @("membershipType","membershipRule","membershipRuleProcessingState") } {
									if ($definition.$property -ne $resource.$property) {
										$change.Actions = @{"Set" = $definition.$property};
									}
								}
								default {
									if ($definition.$property -ne $resource.$property) {
										if(!( ($property -eq "visibility") -and !($resource.$property) -and ($definition.$property -eq "Public") )){
											$change.Actions = @{"Set" = $definition.$property};
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
