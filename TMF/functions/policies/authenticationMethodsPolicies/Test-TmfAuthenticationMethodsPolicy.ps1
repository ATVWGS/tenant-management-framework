function Test-TmfAuthenticationMethodsPolicy {
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
		$resourceName = "authenticationMethodsPolicies"
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
				ResourceType = 'authenticationMethodsPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
				$resource = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationMethodsPolicy")
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
                    Actions = @()
                }

                switch ($property) {
                    "authenticationMethodConfigurations" {

                        foreach ($method in $definition.$property) {
                            $methodChange = $false
                            $methodProperties = ($method | Get-Member -MemberType NoteProperty).Name
                            $resourceMethod = $resource.$property | Where-Object {$_.id -eq $method.id}
							Write-Verbose "Working on $($method.id)"
                            foreach ($methodProperty in $methodProperties) {
                                if ($method.$methodProperty.GetType().Name -in "Object[]", "Hashtable", "PSCustomObject") {
                                    switch ($method.$methodProperty.GetType().Name) {
                                        "Object[]" {
											Write-Verbose "$methodProperty is Object[]"
                                            $objectcount = $method.$methodProperty.count
											if ($objectcount -ne $resourceMethod.$methodProperty.count) {
												$methodChange = $true
											}
											else {
												for ($i=0; $i -lt $objectcount; $i++) {
													foreach ($key in ($method.$methodProperty[$i] | Get-Member -MemberType NoteProperty).Name) {
														if (($method.$methodProperty[$i].$key.GetType()).Name -eq "PSCustomObject") {
															foreach ($subkey in ($method.$methodProperty[$i].$key | Get-Member -MemberType NoteProperty).Name) {
																if (($method.$methodProperty[$i].$key.$subkey.GetType()).Name -eq "Object[]") {
																	if (Compare-Object $method.$methodProperty[$i].$key.$subkey $resourceMethod.$methodProperty[$i].$key.$subkey) {
																		$methodChange = $true
																	}
																}
																else {
																	if ($method.$methodProperty[$i].$key.$subkey -ne $resourceMethod.$methodProperty[$i].$key.$subkey) {
																		$methodChange = $true
																	}
																}
															}
														}
														else {
															if ($method.$methodProperty[$i].$key -ne $resourceMethod.$methodProperty[$i].$key) {
																Write-Verbose $method.$methodProperty[$i].$key
																$methodChange = $true
															}
														}														
													}
												}
											}                                            
                                        }
                                        "Hashtable" {
											Write-Verbose "$methodProperty is Hashtable"
                                            if (-not (Compare-Hashtable ($method.$methodProperty | ConvertTo-PSFHashtable) $resourceMethod.$methodProperty)) {
												Write-Verbose $method.$methodProperty
                                                $methodChange = $true
                                            }
                                        }
                                        "PSCustomObject" {
											Write-Verbose "$methodProperty is PSCustomObject"
                                            foreach ($item in ($method.$methodProperty | Get-Member -MemberType NoteProperty).Name) {
												if ($method.$methodProperty.$item.GetType().Name -eq "Object[]") {
													Write-Verbose "151: $item"
													$objectcount = $method.$methodProperty.$item.count
													if ($objectcount -ne $resourceMethod.$methodProperty.$item.count) {
														$methodChange = $true
													}
													else {
														for ($i=0; $i -lt $objectcount; $i++) {
															if ($method.$methodProperty.$item[$i] | Get-Member -MemberType NoteProperty) {
																foreach ($key in ($method.$methodProperty.$item[$i] | Get-Member -MemberType NoteProperty).Name) {
																	if ($method.$methodProperty.$item[$i].$key -ne $resourceMethod.$methodProperty.$item[$i].$key) {
																		Write-Verbose $item
																		$methodChange = $true
																	}
																}
															}
															else {
																$ref = [string[]]($method.$methodProperty.$item)
																$dif = [string[]]($resourceMethod.$methodProperty.$item)
																if (($ref | Where-Object {$dif -notcontains $_}) -or ($dif | Where-Object {$ref -notcontains $_})) {
																	$methodChange = $true
																}
															}
														}
													}													
												}
												elseif ($method.$methodProperty.$item.GetType().Name -eq "PSCustomObject") {
													Write-Verbose "173: $item"
													foreach ($subitem in ($method.$methodProperty.$item | Get-Member -MemberType NoteProperty).Name) {
														switch (($method.$methodProperty.$item.$subitem.gettype()).Name) {
															"PSCustomObject" {
																if (-not(Compare-Hashtable ($method.$methodProperty.$item.$subitem | ConvertTo-PSFHashtable) $resourceMethod.$methodProperty.$item.$subitem)) {
																	Write-Verbose "Subitem 177 $($subitem)"
																	$methodChange = $true
																}
															}
															"HashTable" {
																if (-not(Compare-Hashtable $method.$methodProperty.$item.$subitem $resourceMethod.$methodProperty.$item.$subitem)) {
																	Write-Verbose "Subitem 183 $($subitem)"
																	$methodChange = $true
																}
															}
															"Object[]" {
																$objectcount = $method.$methodProperty.$item.$subitem.count
																if ($objectcount -ne $resourceMethod.$methodProperty.$item.$subitem.count) {
																	$methodChange = $true
																}
																else {
																	for ($i=0; $i -lt $objectcount; $i++) {
																		if ($method.$methodProperty.$item.$subitem[$i] | Get-Member -MemberType NoteProperty) {
																			foreach ($key in ($method.$methodProperty.$item.$subitem[$i] | Get-Member -MemberType NoteProperty).Name) {
																				if ($method.$methodProperty.$item.$subitem[$i].$key -ne $resourceMethod.$methodProperty.$item.$subitem[$i].$key) {
																					Write-Verbose "Subitem 193 $($subitem)"
																					$methodChange = $true
																				}
																			}
																		}
																		else {
																			$ref = [string[]]($method.$methodProperty.$item.$subitem)
																			$dif = [string[]]($resourceMethod.$methodProperty.$item.$subitem)
																			if (($ref | Where-Object {$dif -notcontains $_}) -or ($dif | Where-Object {$ref -notcontains $_})) {
																				Write-Verbose "Subitem 202 $($subitem)"
																				$methodChange = $true
																			}
																		}
																	}
																}																
															}
															default {
																if ($method.$methodProperty.$item.$subitem -ne $resourceMethod.$methodProperty.$item.$subitem) {
																	Write-Verbose "Subitem 210 $($subitem)"
																	$methodChange = $true
																}
															}
														}
													}
													if (-not (Compare-HashTable ($method.$methodProperty.$item | Convertto-PSFHashtable) $resourceMethod.$methodProperty.$item)) {
														Write-Verbose $item
														$methodChange = $true
													}
												}
												else {
													Write-Verbose "180: $item"
													if ($method.$methodProperty.$item -ne $resourceMethod.$methodProperty.$item) {
														Write-Verbose $item
														$methodChange = $true
													}
												}                                                
                                            }
                                        }
                                    }
                                }
                                else {
									Write-Verbose "$methodProperty is simple NoteProperty"
                                    if ($method.$methodProperty -ne $resourceMethod.$methodProperty) {
                                        $methodChange = $true
                                    }
                                }
                            }

                            if ($methodChange) {
                                $change.Actions += @{"Set" = $method.id}
                            }
                        }
                    }
                    "registrationEnforcement" {

                        $regEnfProperties = ($definition.$property.authenticationMethodsRegistrationCampaign | Get-Member -MemberType NoteProperty).Name
                        foreach ($item in $regEnfProperties) {
                            if ($definition.$property.authenticationMethodsRegistrationCampaign.$item.GetType().Name -in "Object[]", "Hashtable") {
                                switch ($definition.$property.authenticationMethodsRegistrationCampaign.$item.GetType().Name) {
                                    "Object[]" {

                                        if ($definition.$property.authenticationMethodsRegistrationCampaign.$item -and $resource.$property.authenticationMethodsRegistrationCampaign.$item) {
                                            if (Compare-Object ($definition.$property.authenticationMethodsRegistrationCampaign.$item | ConvertTo-PSFHashtable) $resource.$property.authenticationMethodsRegistrationCampaign.$item) {
                                                $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                            }
                                        }
                                        else {
                                            if (((-not ($definition.$property.authenticationMethodsRegistrationCampaign.$item)) -and $resource.$property.authenticationMethodsRegistrationCampaign.$item) -or ($definition.$property.authenticationMethodsRegistrationCampaign.$item -and (-not ($resource.$property.authenticationMethodsRegistrationCampaign.$item)))) {
                                                $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                            }
                                        }
                                    }
                                    "Hashtable" {
                                        if (-not (Compare-Hashtable $definition.$property.authenticationMethodsRegistrationCampaign.$item $resource.$property.authenticationMethodsRegistrationCampaign.$item)) {
                                            $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                        }
                                    }
                                }
                            }
                            else {
                                if ($definition.$property.authenticationMethodsRegistrationCampaign.$item -ne $resource.$property.authenticationMethodsRegistrationCampaign.$item){
                                    $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                }
                            }
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