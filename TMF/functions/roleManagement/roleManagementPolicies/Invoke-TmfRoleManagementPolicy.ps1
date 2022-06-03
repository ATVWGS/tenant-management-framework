function Invoke-TmfRoleManagementPolicy {
    [CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "roleManagementPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "roleManagementPolicies"
			return
		}
	}

    process {
        if (Test-PSFFunctionInterrupt) { return }
        $testResults = Test-TmfRoleManagementPolicy -Cmdlet $Cmdlet

        foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand

            if ($result.DesiredConfiguration.subscriptionReference) {
                $assignmentScope = "AzureResources"
                Test-AzureConnection -Cmdlet $Cmdlet
                $token = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
            }
            else {
                $assignmentScope = "AzureAD"
                Test-GraphConnection
            }

            switch ($assignmentScope) {
                "AzureAD" {
                    switch ($result.ActionType) {
                        "Update" {
                            try {
                                $requestMethod = "PATCH"
                                $policyID = $result.GraphResource."@odata.context".split("'")[1]
                                foreach ($ruleToChange in $result.changes.actions.values) {
                                    $item = $result.DesiredConfiguration.rules | Where-Object {$_.id -eq $ruleToChange}
                                    $requestBody = $item | ConvertTo-Json -Depth 8
                                    Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/policies/roleManagementPolicies/$($policyID)/rules/$($item.id)" -Body $requestBody -ContentType "application/json" | Out-Null
                                }
                                
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "NoActionRequired" {}
                    }
                }
                "AzureResources" {
                    switch ($result.ActionType) {
                        "Update" {
                            try {
                                $requestMethod = "PATCH"
                                $requestBody = @{
                                    "properties" = @{
                                        "rules" = $result.DesiredConfiguration.rules
                                    }
                                }
                                $requestBody = $requestBody | ConvertTo-Json -Depth 8
        
                                Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)providers/Microsoft.Subscription$($result.GraphResource.id)?api-version=2020-10-01-preview" -Headers @{"Authorization"="Bearer $($token)"} -Body $requestBody -ContentType "application/json" | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "NoActionRequired" {}
                    }
                }
            }
        }
    }
}