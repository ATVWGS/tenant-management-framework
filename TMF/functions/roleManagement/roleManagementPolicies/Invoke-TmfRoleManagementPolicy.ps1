function Invoke-TmfRoleManagementPolicy {
    [CmdletBinding()]
	Param (
        [ValidateSet('AzureResources', 'AzureAD', 'AADGroup')]
		[string] $scope,
        [string[]] $SourceFile,
		[string[]] $SourceConfig,
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

        if (($scope -and $SourceFile -and $SourceConfig) -or ($scope -and $SourceFile) -or ($SourceFile -and $SourceConfig)) {
			$exception = New-Object System.Data.DataException("Multiple filters are not supported. You can only filter by one type, sourceFile or sourceConfig or scope!")
			$errorID = "MultipleFiltersNotSupported"
			$category = [System.Management.Automation.ErrorCategory]::NotSpecified
			$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
			$cmdlet.ThrowTerminatingError($recordObject)
		}
	}

    process {
        if (Test-PSFFunctionInterrupt) { return }

        if ($scope) {
            $testResults = Test-TmfRoleManagementPolicy -scope $scope -RawOutput -Cmdlet $Cmdlet
        }
        elseif ($SourceFile) {
            $testResults = Test-TmfRoleManagementPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
        }
        elseif ($SourceConfig) {
            $testResults = Test-TmfRoleManagementPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
        }
        else {
            $testResults = Test-TmfRoleManagementPolicy -RawOutput -Cmdlet $Cmdlet
        }

        foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand

            if ($result.DesiredConfiguration.subscriptionReference) {
                $assignmentScope = "AzureResources"
                Test-AzureConnection -Cmdlet $Cmdlet
                $token = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
            }
            else {
                if ($result.DesiredConfiguration.scopeType -eq "group") {
                    $assignmentScope = "AADGroup"
                }
                else {
                    $assignmentScope = "AzureAD"
                }
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
                "AADGroup" {
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