function Test-TmfRoleAssignment
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
		$resourceName = "roleAssignments"
        $tenant = Get-MgOrganization -Property displayName, Id
	}
	process
	{
    	$definitions = $script:desiredConfiguration[$resourceName]

		foreach ($definition in $definitions) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

            if ($definition.subscriptionReference) {
                $assignmentScope = "AzureResources"
                Test-AzureConnection -Cmdlet $Cmdlet
                $token = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
            }
            else {
                $assignmentScope = "AzureAD"
            }

            switch ($assignmentScope) {
                "AzureResources" {
                    $result = @{
                        Tenant = $tenant.Name
                        TenantId = $tenant.Id
                        ResourceType = 'roleAssignment'
                        ResourceName = "$($definition.principalReference)_$($definition.roleReference)_$($definition.scopeReference)"
                        DesiredConfiguration = $definition
                    }
                    
                    try {
        
                        $subscriptionId = Resolve-Subscription -InputReference $definition.subscriptionReference
                        $roleDefinitionId = Resolve-AzureRoleDefinition -InputReference $definition.roleReference -SubscriptionId $subscriptionId.trimStart("/")
                        switch ($definition.principalType) {
                            "group" {$principalId=Resolve-Group -InputReference $definition.principalReference -SearchInDesiredConfiguration}
                            "user"  {$principalId=Resolve-User -InputReference $definition.principalReference}
                        }
        
                        switch ($definition.scopeType) {
                            "subscription" {$scopeId = $subscriptionId}
                            "resourceGroup" {$scopeId = Resolve-ResourceGroup -InputReference $definition.scopeReference -SubscriptionId $subscriptionId}
                        }
        
                        switch ($definition.type) {
                            "eligible" {
                                try {
                                    $resource = @()
                                    $resource += (Invoke-RestMethod -Method GET -Uri ("$($script:apiBaseUrl)providers/Microsoft.Subscription$($scopeId)/providers/Microsoft.Authorization/roleEligibilitySchedules?`$filter=principalId eq '{0}'&api-version=2020-10-01-preview" -f $principalId) -Headers @{"Authorization"="Bearer $($token)"}).value | Where-Object {$_.properties.roleDefinitionId -eq $roleDefinitionId}
                                }
                                catch {
                                    $resource = @()
                                }
                            }
                            
                            "active" {
                                try {
                                    $resource = @()
                                    $resource += (Invoke-RestMethod -Method GET -Uri ("$($script:apiBaseUrl)$($scopeId.TrimStart("/"))/providers/Microsoft.Authorization/roleAssignments?`$filter=principalId eq '{0}'&api-version=2020-10-01-preview" -f $principalId) -Headers @{"Authorization"="Bearer $($token)"}).value | Where-Object {$_.properties.roleDefinitionId -eq $roleDefinitionId}
                                }
                                catch {
                                    $resource = @()
                                }
                            }
                        }
                    }
                    catch {
                        Write-PSFMessage -Level Warning -String 'Tmf.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
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
                                if ($definition.type -eq "eligible") {
                                    foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "present"})) {
                                        $change = [PSCustomObject] @{
                                            Property = $property										
                                            Actions = $null
                                        }
                                        switch ($property) {
                                            "startDateTime" {
                                                if ($definition.startDateTime -ne $resource.properties.startDateTime -and $definition.startDateTime -ge (Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0)) {
                                                    $change.Actions = @{"Set" = $definition.$property}
                                                }
                                            }
                                            
                                            "endDateTime" {
                                                if ($definition.expirationType -eq "AfterDateTime") {
                                                    if ($definition.endDateTime -ne $resource.properties.endDateTime) {
                                                        $change.Actions = @{"Set" = $definition.$property}
                                                    }
                                                }
                                            }
        
                                            "expirationType" {
                                                if ($definition.expirationType -eq "noExpiration" -and $resource.properties.endDateTime) {
                                                    $change.Actions = @{"Set" = $definition.$property}
                                                }
                                                if ($definition.expirationType -ne "noExpiration" -and -not ($resource.properties.endDateTime)) {
                                                    $change.Actions = @{"Set" = $definition.$property}
                                                }
                                            }
                                        }
                                        
                                        if ($change.Actions) {$changes += $change}
                                    }	
                                }
                                
                                if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
                                else { $result = New-TestResult @result -ActionType "NoActionRequired" }
                            }
                            else {
                                $result = New-TestResult @result -ActionType "Delete"
                            }
                        }
                        default {
                            Write-PSFMessage -Level Warning -String 'Tmf.Test.MultipleResourcesError' -StringValues $resourceName, $definition.displayName -Tag 'failed'
                            $exception = New-Object System.Data.DataException("Query returned multiple results. Cannot decide which resource to test.")
                            $errorID = 'MultipleResourcesError'
                            $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                            $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                            $cmdlet.ThrowTerminatingError($recordObject)
                        }
                    }
                    
                    $result
                }
                "AzureAD" {
                    $result = @{
                        Tenant = $tenant.Name
                        TenantId = $tenant.Id
                        ResourceType = 'roleAssignment'
                        ResourceName = "$($definition.principalReference)_$($definition.roleReference)_$($definition.directoryScopeReference)"
                        DesiredConfiguration = $definition
                    }
                    
                    try {
        
                        $roleDefinitionId = Resolve-DirectoryRoleDefinition -InputReference $definition.roleReference
                        switch ($definition.principalType) {
                            "group" {$principalId=Resolve-Group -InputReference $definition.principalReference -SearchInDesiredConfiguration}
                            "user"  {$principalId=Resolve-User -InputReference $definition.principalReference}
                            "servicePrincipal"  {$principalId=Resolve-ServicePrincipal -InputReference $definition.principalReference}
                        }
                        switch ($definition.directoryScopeType) {
                            "directory" {$directoryScopeId="/"}
                            "administrativeUnit" {$directoryScopeId="/administrativeUnits/"+$(Resolve-AdministrativeUnit -InputReference $definition.directoryScopeReference -SearchInDesiredConfiguration)}
                            
                        }

                        switch ($definition.type) {
                            "eligible" {
                                try {
                                    $resource = @()
                                    $resource += (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/roleManagement/directory/roleEligibilitySchedules?`$filter=principalId eq '{0}' and roleDefinitionId eq '{1}' and directoryScopeId eq '{2}'" -f $principalId,$roleDefinitionId,$directoryScopeId)).value
                                }
                                catch {
                                    $resource = @()
                                }
                            }
                            
                            "active" {
                                try {
                                    $resource = @()
                                    $resource += (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/roleManagement/directory/roleAssignmentSchedules?`$filter=principalId eq '{0}' and roleDefinitionId eq '{1}' and directoryScopeId eq '{2}'" -f $principalId,$roleDefinitionId,$directoryScopeId)).value
                                }
                                catch {
                                    $resource = @()
                                }
                            }
                        }
                    }
                    catch {
                        Write-PSFMessage -Level Warning -String 'Tmf.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
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

                                foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "present", "startDateTime"})) {
                                    $change = [PSCustomObject] @{
                                        Property = $property										
                                        Actions = $null
                                    }
                                    switch ($property) {
                                        "endDateTime" {
                                            if ($definition.expirationType -eq "AfterDateTime") {
                                                if ($definition.endDateTime -ne $resource.scheduleInfo.expiration.endDateTime) {
                                                    $change.Actions = @{"Set" = $definition.$property}
                                                }
                                            }
                                        }
    
                                        "expirationType" {
                                            if ($definition.expirationType -eq "noExpiration" -and $resource.scheduleInfo.expiration.endDateTime) {
                                                $change.Actions = @{"Set" = $definition.$property}
                                            }
                                            if ($definition.expirationType -ne "noExpiration" -and -not ($resource.scheduleInfo.expiration.endDateTime)) {
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
                            Write-PSFMessage -Level Warning -String 'Tmf.Test.MultipleResourcesError' -StringValues $resourceName, $definition.displayName -Tag 'failed'
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
	}
}
