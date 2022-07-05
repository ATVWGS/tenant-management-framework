function Invoke-TmfRoleAssignment {
    [CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
		
	
	begin
	{
		$resourceName = "roleAssignments"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "roleAssignment"
			return
		}
        Test-AzureConnection
        $azureToken = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
	}

    process {
        if (Test-PSFFunctionInterrupt) { return }
        $testResults = Test-TmfRoleAssignment -Cmdlet $Cmdlet

        foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand

            if ($result.DesiredConfiguration.subscriptionReference) {
                $assignmentScope = "AzureResources"
                Test-AzureConnection
                $azureToken = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
            }
            else {
                $assignmentScope = "AzureAD"
                Test-GraphConnection
            }

            switch ($assignmentScope) {

                "AzureResources" {
                    switch ($result.ActionType) {
                        "Create" {
                            try {
                                $requestMethod = "PUT"
                                $subscriptionId = Resolve-Subscription -InputReference $result.DesiredConfiguration.subscriptionReference
                                switch ($result.DesiredConfiguration.scopeType) {
                                    "subscription" {$scopeId = $subscriptionId}
                                    "resourceGroup" {$scopeId = Resolve-ResourceGroup -InputReference $result.DesiredConfiguration.scopeReference -SubscriptionId $subscriptionId}
                                }
                                switch ($result.DesiredConfiguration.principalType) {
                                    "group" {
                                        $principalId = Resolve-Group -InputReference $result.DesiredConfiguration.principalReference
                                    }
                                    "user" {
                                        $principalId = Resolve-User -InputReference $result.DesiredConfiguration.principalReference
                                    }
                                    "servicePrincipal"  {
                                        $principalId = Resolve-ServicePrincipal -InputReference $result.DesiredConfiguration.principalReference
                                    }
                                }
                                $roleDefinitionId = Resolve-AzureRoleDefinition -InputReference $result.DesiredConfiguration.roleReference -SubscriptionId $subscriptionId
                                switch ($result.DesiredConfiguration.expirationType) {
                                    "noExpiration" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                                "requestType" = "AdminAssign"
                                                "scheduleInfo" = @{
                                                    "startDateTime" = $result.DesiredConfiguration.startDateTime
                                                    "expiration" = @{
                                                        "type" = "noExpiration"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    "AfterDateTime" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                                "requestType" = "AdminAssign"
                                                "scheduleInfo" = @{
                                                    "startDateTime" = $result.DesiredConfiguration.startDateTime
                                                    "expiration" = @{
                                                        "type" = "AfterDateTime"
                                                        "endDateTime" = $result.DesiredConfiguration.endDateTime
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    "AfterDuration" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                                "requestType" = "AdminAssign"
                                                "scheduleInfo" = @{
                                                    "startDateTime" = $result.DesiredConfiguration.startDateTime
                                                    "expiration" = @{
                                                        "type" = "AfterDuration"
                                                        "duration" = $result.DesiredConfiguration.duration
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                $guid = (New-Guid).Guid
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                switch ($result.DesiredConfiguration.type) {
                                    "eligible" {
                                        Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($scopeId.trimStart("/"))/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/$($guid)?api-version=2020-10-01-preview" -Headers @{"Authorization"="Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                    "active" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                            }
                                        }
                                        $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                        Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($scopeId.trimStart("/"))/providers/Microsoft.Authorization/roleAssignments/$($guid)?api-version=2018-01-01-preview" -Headers @{"Authorization"="Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                }
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
                                switch ($result.DesiredConfiguration.principalType) {
                                    "group" {
                                        $principalId = Resolve-Group -InputReference $result.DesiredConfiguration.principalReference
                                    }
                                    "user" {
                                        $principalId = Resolve-User -InputReference $result.DesiredConfiguration.principalReference
                                    }
                                    "servicePrincipal"  {
                                        $principalId = Resolve-ServicePrincipal -InputReference $result.DesiredConfiguration.principalReference
                                    }
                                }
                                $subscriptionId = Resolve-Subscription -InputReference $result.DesiredConfiguration.subscriptionReference
                                $roleDefinitionId = Resolve-AzureRoleDefinition -InputReference $result.DesiredConfiguration.roleReference -SubscriptionId $subscriptionId.trimStart("/")
                                switch ($result.DesiredConfiguration.expirationType) {
                                    "noExpiration" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                                "requestType" = "AdminUpdate"
                                                "scheduleInfo" = @{
                                                    "startDateTime" = $result.DesiredConfiguration.startDateTime
                                                    "expiration" = @{
                                                        "endDateTime" = $null
                                                        "type" = "noExpiration"
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    "AfterDateTime" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                                "requestType" = "AdminUpdate"
                                                "scheduleInfo" = @{
                                                    "startDateTime" = $result.DesiredConfiguration.startDateTime
                                                    "expiration" = @{
                                                        "type" = "AfterDateTime"
                                                        "endDateTime" = $result.DesiredConfiguration.endDateTime
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    "AfterDuration" {
                                        $requestBody = @{
                                            "properties"= @{
                                                "principalId" = $principalId
                                                "roleDefinitionId" = $roleDefinitionId
                                                "requestType" = "AdminUpdate"
                                                "scheduleInfo" = @{
                                                    "startDateTime" = $result.DesiredConfiguration.startDateTime
                                                    "expiration" = @{
                                                        "type" = "AfterDuration"
                                                        "duration" = $result.DesiredConfiguration.duration
                                                        "endDateTIme" = $null
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                $guid = (New-Guid).Guid
                                switch ($result.DesiredConfiguration.type) {
                                    "eligible" {
                                        Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($result.AzureResource.properties.scope.trimStart("/"))/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/$($guid)?api-version=2020-10-01-preview" -Headers @{"Authorization"="Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                    "active" {
                                        Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($result.AzureResource.properties.scope.trimStart("/"))/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$($guid)?api-version=2020-10-01-preview" -Headers @{"Authorization"="Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                }
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "Delete" {
                            $requestMethod = "PUT"
                            switch ($result.DesiredConfiguration.principalType) {
                                "group" {
                                    $principalId = Resolve-Group -InputReference $result.DesiredConfiguration.principalReference
                                }
                                "user" {
                                    $principalId = Resolve-User -InputReference $result.DesiredConfiguration.principalReference
                                }
                                "servicePrincipal"  {
                                    $principalId = Resolve-ServicePrincipal -InputReference $result.DesiredConfiguration.principalReference
                                }
                            }
                            $subscriptionId = Resolve-Subscription -InputReference $result.DesiredConfiguration.subscriptionReference
                            $roleDefinitionId = Resolve-AzureRoleDefinition -InputReference $result.DesiredConfiguration.roleReference -SubscriptionId $subscriptionId.trimStart("/")
                            try {
        
                                $requestBody = @{
                                    "properties" = @{
                                        "principalId" = $principalId
                                        "roleDefinitionId" = $roleDefinitionId
                                        "requestType" = "AdminRemove"
                                    }
                                }
        
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                $guid = (New-Guid).Guid
                                switch ($result.DesiredConfiguration.type) {
                                    "eligible" {
                                        Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($result.GraphResource.properties.scope.trimStart("/"))/providers/Microsoft.Authorization/roleEligibilityScheduleRequests/$($guid)?api-version=2020-10-01-preview" -Headers @{"Authorization" = "Bearer $($azureToken)"} -Body $requestBody -ContentType "application/json" | Out-Null
                                    }
                                    "active" {
                                        $requestMethod = "DELETE"
                                        Invoke-RestMethod -Method $requestMethod -Uri "$($script:apiBaseUrl)$($result.GraphResource.id.trimStart("/"))?api-version=2018-01-01-preview" -Headers @{"Authorization" = "Bearer $($azureToken)"}  | Out-Null
                                    }
                                }
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
                            try {
                                $requestMethod = "POST"
                                switch ($result.DesiredConfiguration.directoryScopeType) {
                                    "directory" {$directoryScopeId="/"}
                                    "administrativeUnit" {$directoryScopeId=Resolve-AdministrativeUnit -InputReference $result.DesiredConfiguration.directoryScopeReference -SearchInDesiredConfiguration}
                                }
                                switch ($result.DesiredConfiguration.principalType) {
                                    "group" { $principalId = Resolve-Group -InputReference $result.DesiredConfiguration.principalReference}
                                    "user" { $principalId = Resolve-User -InputReference $result.DesiredConfiguration.principalReference}
                                    "servicePrincipal"  { $principalId = Resolve-ServicePrincipal -InputReference $result.DesiredConfiguration.principalReference}
                                }
                                $roleDefinitionId = Resolve-DirectoryRoleDefinition -InputReference $result.DesiredConfiguration.roleReference
                                switch ($result.DesiredConfiguration.expirationType) {
                                    "noExpiration" {
                                        $requestBody = @{
                                            "action" = "AdminAssign"
                                            "justification" = "Assignment with TMF"
                                            "roleDefinitionId" = $roleDefinitionId
                                            "directoryScopeId" = $directoryScopeId
                                            "principalId" = $principalId
                                            "scheduleInfo" = @{
                                              "startDateTime" = get-date ($result.DesiredConfiguration.startDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                              "expiration" = @{
                                                "type" = "noExpiration"
                                              }
                                            }
                                        }
                                    }
                                    "AfterDateTime" {
                                        $requestBody = [ordered]@{
                                            "action" = "AdminAssign"
                                            "justification" = "Assignment with TMF"
                                            "roleDefinitionId" = $roleDefinitionId
                                            "directoryScopeId" = $directoryScopeId
                                            "principalId" = $principalId
                                            "scheduleInfo" = @{
                                                "startDateTime" = get-date ($result.DesiredConfiguration.startDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                "expiration" = @{
                                                    "type" = "AfterDateTime"
                                                    "endDateTime" = get-date ($result.DesiredConfiguration.endDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                }
                                            }
                                        }
                                    }
                                    "AfterDuration" {
                                        $requestBody = [ordered]@{
                                            "action" = "AdminAssign"
                                            "justification" = "Assignment with TMF"
                                            "roleDefinitionId" = $roleDefinitionId
                                            "directoryScopeId" = $directoryScopeId
                                            "principalId" = $principalId
                                            "scheduleInfo" = @{
                                                "startDateTime" = get-date ($result.DesiredConfiguration.startDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                "expiration" = @{
                                                    "type" = "AfterDuration"
                                                    "duration" = $result.DesiredConfiguration.duration
                                                }
                                            }
                                        }
                                    }
                                }
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                $requestBody
                                switch ($result.DesiredConfiguration.type) {
                                    "eligible" {
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleEligibilityScheduleRequests" -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                    "active" {
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleAssignmentScheduleRequests" -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                }
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                         }
                        "Update" {
                            try {
                                $requestMethod = "POST"
                                switch ($result.DesiredConfiguration.principalType) {
                                    "group" {$principalId = Resolve-Group -InputReference $result.DesiredConfiguration.principalReference}
                                    "user" {$principalId = Resolve-User -InputReference $result.DesiredConfiguration.principalReference}
                                    "servicePrincipal"  {$principalId = Resolve-ServicePrincipal -InputReference $result.DesiredConfiguration.principalReference}
                                }
                                switch ($result.DesiredConfiguration.directoryScopeType) {
                                    "directory" {$directoryScopeId="/"}
                                    "administrativeUnit" {$directoryScopeId=Resolve-AdministrativeUnit -InputReference $result.DesiredConfiguration.directoryScopeReference -SearchInDesiredConfiguration}
                                }
                                $roleDefinitionId = Resolve-DirectoryRoleDefinition -InputReference $result.DesiredConfiguration.roleReference
                                switch ($result.DesiredConfiguration.expirationType) {
                                    "noExpiration" {
                                        $requestBody = [ordered]@{
                                            "action" = "AdminUpdate"
                                            "roleDefinitionId" = $roleDefinitionId
                                            "directoryScopeId" = $directoryScopeId
                                            "principalId" = $principalId
                                            "scheduleInfo" = @{
                                                "startDateTime" = get-date ($result.DesiredConfiguration.startDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                "expiration" = @{
                                                    "endDateTime" = $null
                                                    "type" = "noExpiration"
                                                }
                                            }
                                        }
                                    }
                                    "AfterDateTime" {
                                        $requestBody = [ordered]@{
                                            "action" = "AdminUpdate"
                                            "roleDefinitionId" = $roleDefinitionId
                                            "directoryScopeId" = $directoryScopeId
                                            "principalId" = $principalId
                                            "scheduleInfo" = @{
                                                "startDateTime" = get-date ($result.DesiredConfiguration.startDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                "expiration" = @{
                                                    "type" = "AfterDateTime"
                                                    "endDateTime" = get-date ($result.DesiredConfiguration.endDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                }
                                            }
                                        }
                                    }
                                    "AfterDuration" {
                                        $requestBody = [ordered]@{
                                            "action" = "AdminUpdate"
                                            "roleDefinitionId" = $roleDefinitionId
                                            "directoryScopeId" = $directoryScopeId
                                            "principalId" = $principalId
                                            "scheduleInfo" = @{
                                                "startDateTime" = get-date ($result.DesiredConfiguration.startDateTime) -UFormat "%Y-%m-%dT%H:%M%:%SZ"
                                                "expiration" = @{
                                                    "type" = "AfterDuration"
                                                    "duration" = $result.DesiredConfiguration.duration
                                                    "endDateTIme" = $null
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5
                                $requestBody
                                switch ($result.DesiredConfiguration.type) {
                                    "eligible" {
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleEligibilityScheduleRequests" -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                    "active" {
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleAssignmentScheduleRequests" -Body $requestBody -ContentType "application/json"  | Out-Null
                                    }
                                }
                                Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                            }
                            catch {
                                Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                                throw $_
                            }
                        }
                        "Delete" {
                            $requestMethod = "POST"
                            switch ($result.DesiredConfiguration.principalType) {
                                "group" {$principalId = Resolve-Group -InputReference $result.DesiredConfiguration.principalReference}
                                "user" {$principalId = Resolve-User -InputReference $result.DesiredConfiguration.principalReference}
                                "servicePrincipal"  {$principalId = Resolve-ServicePrincipal -InputReference $result.DesiredConfiguration.principalReference}
                            }
                            switch ($result.DesiredConfiguration.directoryScopeType) {
                                "directory" {$directoryScopeId="/"}
                                "administrativeUnit" {$directoryScopeId=Resolve-AdministrativeUnit -InputReference $result.DesiredConfiguration.directoryScopeReference -SearchInDesiredConfiguration}
                            }
                            $roleDefinitionId = Resolve-DirectoryRoleDefinition -InputReference $result.DesiredConfiguration.roleReference
                            try {
        
                                $requestBody = [ordered]@{
                                    "action" = "AdminRemove"
                                    "justification" = "Remove assignment with TMF"
                                    "roleDefinitionId" = $roleDefinitionId                                 
                                    "directoryScopeId" = $directoryScopeId
                                    "principalId" = $principalId
                                }
        
                                $requestBody = $requestBody | ConvertTo-Json -Depth 5

                                switch ($result.DesiredConfiguration.type) {
                                    "eligible" {
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleEligibilityScheduleRequests" -Body $requestBody -ContentType "application/json" | Out-Null
                                    }
                                    "active" {
                                        Invoke-MgGraphRequest -Method $requestMethod -Uri "$($script:graphBaseUrl)/roleManagement/directory/roleAssignmentScheduleRequests" -Body $requestBody -ContentType "application/json" | Out-Null
                                    }
                                }
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