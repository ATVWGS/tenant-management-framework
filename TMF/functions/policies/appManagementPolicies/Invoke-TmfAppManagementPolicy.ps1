function Invoke-TmfAppManagementPolicy {
    <#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
        [string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "appManagementPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "appManagementPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
        
        if ($SpecificResources) {
            $testResults = Test-TmfAppManagementPolicy -SpecificResources $SpecificResources -Cmdlet $Cmdlet
        }
        else {
            $testResults = Test-TmfAppManagementPolicy -Cmdlet $Cmdlet
        }
        		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl/policies/appManagementPolicies"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"description" = $result.DesiredConfiguration.description
                        "isEnabled" = $result.DesiredConfiguration.isEnabled
                        "restrictions" = $result.DesiredConfiguration.restrictions
					}
					try {						
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                        Write-Host $requestBody
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						$policy = Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}

                    if ($result.DesiredConfiguration.appliesTo) {
                        foreach ($item in $result.DesiredConfiguration.appliesTo) {
                            $requestUrl = "$script:graphBaseUrl/applications/$item/appManagementPolicies/`$ref"
                            $requestMethod = "POST"
                            $requestBody = @{
                                "@odata.id" = "$script:graphBaseUrl/policies/appManagementPolicies/$($policy.id)"
                            }
                            $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
						    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						    Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                        }
                    }
                }
                "Update" {
                    if ($result.Changes.property -contains "appliesTo" -and $result.Changes.Count -gt 1) {
                        $existingAppliesTo = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/policies/appManagementPolicies/{0}/appliesTo" -f $result.GraphResource.id)).Value.Id
                        Compare-Object -ReferenceObject $result.DesiredConfiguration.appliesTo -DifferenceObject $existingAppliesTo | ForEach-Object {
                            $app = $_.InputObject
                            switch ($_.SideIndicator) {
                                "<=" {
                                    $requestUrl = "$script:graphBaseUrl/applications/{0}/appManagementPolicies/`$ref" -f $app
                                    $requestMethod = "POST"
                                    $requestBody = @{
                                        "@odata.id" = "$script:graphBaseUrl/policies/appManagementPolicies/{0}" -f $result.GraphResource.id
                                    }
                                    $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                                    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                    Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                                }
                                "=>" {
                                    $requestUrl = "$script:graphBaseUrl/applications/{0}/appManagementPolicies/{1}/`$ref" -f $app,$result.GraphResource.id
                                    $requestMethod = "DELETE"
                                    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                    Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl | Out-Null
                                }
                            }
                        }

                        $requestUrl = "$script:graphBaseUrl/policies/appManagementPolicies/{0}" -f $result.GraphResource.Id
                        $requestMethod = "PATCH"
                        $requestBody = @{						
                            "displayName" = $result.DesiredConfiguration.displayName
                            "description" = $result.DesiredConfiguration.description
                            "isEnabled" = $result.DesiredConfiguration.isEnabled
                            "restrictions" = $result.DesiredConfiguration.restrictions
                        }
                        try {						
                            $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                            Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                            $policy = Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
                        }
                        catch {
                            Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                            throw $_
                        }
                    }
                    else {
                        if ($result.Changes.property -contains "appliesTo") {
                            $existingAppliesTo = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/policies/appManagementPolicies/{0}/appliesTo" -f $result.GraphResource.id)).Value.Id
                            Compare-Object -ReferenceObject $result.DesiredConfiguration.appliesTo -DifferenceObject $existingAppliesTo | ForEach-Object {
                                $app = $_.InputObject
                                switch ($_.SideIndicator) {
                                    "<=" {
                                        $requestUrl = "$script:graphBaseUrl/applications/{0}/appManagementPolicies/`$ref" -f $app
                                        $requestMethod = "POST"
                                        $requestBody = @{
                                            "@odata.id" = "$script:graphBaseUrl/policies/appManagementPolicies/{0}" -f $result.GraphResource.id
                                        }
                                        $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                                    }
                                    "=>" {
                                        $requestUrl = "$script:graphBaseUrl/applications/{0}/appManagementPolicies/{1}/`$ref" -f $app,$result.GraphResource.Id
                                        $requestMethod = "DELETE"
                                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl | Out-Null
                                    }
                                }
                            }
                        }
                        else {
                            $requestUrl = "$script:graphBaseUrl/policies/appManagementPolicies/{0}" -f $result.GraphResource.Id
                            $requestMethod = "PATCH"
                            $requestBody = @{						
                                "displayName" = $result.DesiredConfiguration.displayName
                                "description" = $result.DesiredConfiguration.description
                                "isEnabled" = $result.DesiredConfiguration.isEnabled
                                "restrictions" = $result.DesiredConfiguration.restrictions
                            }
                            try {						
                                $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                                Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                $policy = Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }                        
                    }
                }
                "Delete" {
                    $requestUrl = "$script:graphBaseUrl/policies/appManagementPolicies/{0}" -f $result.GraphResource.Id
					$requestMethod = "DELETE"
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
                }
                "NoActionRequired" {}
                default {
					Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.ActionType
				}
            }
            Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
        }
    }

    end {}
}