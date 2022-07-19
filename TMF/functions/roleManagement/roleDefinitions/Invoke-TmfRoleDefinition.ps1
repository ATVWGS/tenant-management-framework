function Invoke-TmfRoleDefinition
{
    [CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "roleDefinitions"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "roleDefinitions"
			return
		}
	}

    process {
        if (Test-PSFFunctionInterrupt) { return }
        $testResults = Test-TmfRoleDefinition -Cmdlet $Cmdlet

        foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand

            if ($result.DesiredConfiguration.subscriptionReference) {
                $roleDefinitionScope = "AzureResources"
                Test-AzureConnection
                $azureToken = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
            }
            else {
                $roleDefinitionScope = "AzureAD"
                Test-GraphConnection
            }
            switch ($roleDefinitionScope) {
                "AzureResources" {
                    switch ($result.ActionType) {
                        "Create" {
                            try {
                                $requestMethod = "PUT"
                                $subscriptionId = Resolve-Subscription -InputReference $result.desiredConfiguration.subscriptionReference
                                $requestBody = @{
                                    "properties" = @{
                                        "roleName" = $result.DesiredConfiguration.displayName
                                        "description" = $result.DesiredConfiguration.description
                                        "assignableScopes" = $result.DesiredConfiguration.assignableScopes
                                        "permissions" = $result.DesiredConfiguration.permissions
                                    }
                                }
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                $guid = (New-Guid).Guid
        
                                Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($subscriptionId.trimStart("/"))/providers/Microsoft.Authorization/roleDefinitions/$($guid)?api-version=2018-01-01-preview" -Headers @{"Authorization" = "Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json"  | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "Update" {
                            try {
                                $requestMethod = "PUT"
                                $requestBody = @{
                                    "properties" = @{
                                        "roleName" = $result.DesiredConfiguration.displayName
                                        "description" = $result.DesiredConfiguration.description
                                        "assignableScopes" = $result.DesiredConfiguration.assignableScopes
                                        "permissions" = $result.DesiredConfiguration.permissions
                                    }
                                }
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
        
                                Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($result.GraphResource.id.trimStart("/"))?api-version=2018-01-01-preview" -Headers @{"Authorization" = "Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json"  | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "Delete" {
                            try {
                                $requestMethod = "DELETE"
        
                                Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($result.GraphResource.id.trimStart("/"))?api-version=2018-01-01-preview" -Headers @{"Authorization" = "Bearer $($azureToken)"}  | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
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
                }

                "AzureAD" {
                    switch ($result.ActionType) {
                        "Create" {
                            $requestMethod = "POST"
                            $requestBody = @{
                                "displayname" = $result.DesiredConfiguration.displayName
                                "description" = $result.DesiredConfiguration.description
                                "rolePermissions" = $result.DesiredConfiguration.rolePermissions
                                "isEnabled" = $true
                            }
                            $requestBody = $requestBody | ConvertTo-Json -Depth 5

                            try {
                                Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleDefinitions" -Body $requestBody -ContentType "application/json" | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "Update" {
                            $requestMethod = "PATCH"
                            $requestBody = @{
                                "displayname" = $result.DesiredConfiguration.displayName
                                "description" = $result.DesiredConfiguration.description
                                "rolePermissions" = $result.DesiredConfiguration.rolePermissions
                            }
                            $requestBody = $requestBody | ConvertTo-Json -Depth 5

                            try {
                                Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleDefinitions/$($result.GraphResource.id)" -Body $requestBody -ContentType "application/json" | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "Delete" {
                            $requestMethod = "DELETE"

                            try {
                                Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleDefinitions/$($result.GraphResource.id)" | Out-Null
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
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
                }
            }
        }	
    }
}