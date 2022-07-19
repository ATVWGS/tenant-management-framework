function Test-TmfRoleManagementPolicy {
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
	
	begin {
        Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "roleManagementPolicies"
        $tenant = Get-MgOrganization -Property displayName, Id
    }

    process {
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
                        ResourceType = 'roleManagementPolicy'
                        ResourceName = "Policy for $($definition.roleReference) role in $($definition.subscriptionReference)"
                        DesiredConfiguration = $definition
                    }

                    $subscriptionId = Resolve-Subscription -InputReference $definition.subscriptionReference
                    $roleId = Resolve-AzureRoleDefinition -InputReference $definition.roleReference -SubscriptionId $subscriptionId
                    $policyId = (Invoke-RestMethod -Method "GET" -Uri "https://management.azure.com/providers/Microsoft.Subscription$($subscriptionId)/providers/Microsoft.Authorization/roleManagementPolicyAssignments?`$filter=roleDefinitionId eq '$($roleId)'&api-version=2020-10-01-preview" -Headers @{"Authorization" = "Bearer $($token)"}).value.properties.policyId
                    $resource = @()
                    $resource += Invoke-RestMethod -Method "GET" -Uri "https://management.azure.com/providers/Microsoft.Subscription$($policyId)?api-version=2020-10-01-preview" -Headers @{"Authorization" = "Bearer $($token)"}

                    $result["GraphResource"] = $resource
                }

                "AzureAD" {
                    $result = @{
                        Tenant = $tenant.Name
                        TenantId = $tenant.Id
                        ResourceType = 'roleManagementPolicy'
                        ResourceName = "Policy for $($definition.roleReference) role"
                        DesiredConfiguration = $definition
                    }
                    $roleId = Resolve-DirectoryRoleDefinition -InputReference $definition.roleReference
                    $policyId = (Invoke-MgGraphRequest -Method "GET" -Uri "$($script:graphBaseUrl)/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '/' and scopeType eq 'Directory' and roleDefinitionId eq '$($roleId)'").value.policyId
                    $resource = @()
                    $resource += Invoke-MgGraphRequest -Method "GET" -Uri "$($script:graphBaseUrl)/policies/roleManagementPolicies/$($policyId)/rules"
                    
                    $result["GraphResource"] = $resource
                }
            }
            
            $rules = @()
            $rules += ($script:desiredConfiguration["roleManagementPolicyRuleTemplates"] | Where-Object {$_.displayName -eq $definition.ruleTemplate}).rules

            if (-not ($rules)) {
                Write-PSFMessage -Level Warning -String 'TMF.Test.MissingPolicyRuleTemplate' -StringValues $resourceName, $definition.ruleTemplate -Tag 'failed'
                $exception = New-Object System.Data.DataException("Referenced policy rule template not found.")
                $errorID = 'MissingPolicyRuleTemplate'
                $category = [System.Management.Automation.ErrorCategory]::NotSpecified
                $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
                $cmdlet.ThrowTerminatingError($recordObject)
            }

            if ($definition.activationApprover.reference) {
                
                $primaryApprovers = @()
                foreach ($item in $definition.activationApprover) {

                    switch ($item.type) {
                        "user" {
                            $referenceID = Resolve-User -InputReference $item.reference
                            switch ($assignmentScope) {
                                "AzureAD" {
                                    $primaryApprovers +=  @{
                                        "id" = $referenceID
                                        "isBackup" = $false
                                        "@odata.type" = "#microsoft.graph.singleUser"
                                    }
                                }
                                "AzureResources" {
                                    $primaryApprovers += @{
                                        "id" = $referenceID
                                        "isBackup" = $false
                                        "userType" = "User"
                                    }
                                }
                            }
                        }
                        "group" {
                            $referenceID = Resolve-Group -InputReference $item.reference
                            switch ($assignmentScope) {
                                "AzureAD" {
                                    $primaryApprovers +=  [PSCustomObject]@{
                                        "id" = $referenceID
                                        "isBackup" = $false
                                        "@odata.type" = "#microsoft.graph.groupMembers"
                                    }
                                }
                                "AzureResources"{
                                    $primaryApprovers += [PSCustomObject]@{
                                        "id" = $referenceID
                                        "isBackup" = $false
                                        "userType" = "Group"
                                    }
                                }
                            }
                        }
                    }
                }    

                switch ($assignmentScope) {
                    "AzureAD" {
                        $activationApprover = [PSCustomObject]@{
                            
                            "setting"=  @{
                                "isApprovalRequired" = $true
                                "isApprovalRequiredForExtension" = $false
                                "isRequestorJustificationRequired" = $true
                                "approvalMode" = "SingleStage"
                                "approvalStages"= @(
                                    @{
                                        "approvalStageTimeOutInDays" = 1
                                        "isApproverJustificationRequired" = $true
                                        "escalationTimeInMinutes" = 0
                                        "primaryApprovers" = $primaryApprovers
                                        "isEscalationEnabled" = $false
                                    }
                                )
                            }
                            "id" = "Approval_EndUser_Assignment"
                            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
                            "target" = @{
                                "caller" = "EndUser"
                                "operations" = @(
                                    "All"
                                )
                                "level" = "Assignment"
                                "inheritableSettings" = @()
                                "enforcedSettings" = @()
                            }
                        }
                        $rules += $activationApprover
                    }
                    "AzureResources" {
                        $activationApprover = [PSCustomObject]@{
                            
                            "setting"= @{
                                "isApprovalRequired" = $true
                                "isApprovalRequiredForExtension" = $false
                                "isRequestorJustificationRequired" = $true
                                "approvalMode" = "SingleStage"
                                "approvalStages"= @(
                                @{
                                    "approvalStageTimeOutInDays" = 1
                                    "isApproverJustificationRequired" = $true
                                    "escalationTimeInMinutes" = 0
                                    "primaryApprovers" = $primaryApprovers
                                    "isEscalationEnabled" = $false
                                }
                                )
                            }
                            "id" = "Approval_EndUser_Assignment"
                            "ruleType" = "RoleManagementPolicyApprovalRule"
                            "target" = @{
                                "caller" = "EndUser"
                                "operations" = @(
                                    "All"
                                )
                                "level" = "Assignment"
                            }
                        }
                        $rules += $activationApprover
                    }
                }
            }
            else {
                switch ($assignmentScope) {
                    "AzureAD" {
                        $activationApprover = [PSCustomObject]@{
                            
                            "setting"=  @{
                                "isApprovalRequired" = $false
                                "isApprovalRequiredForExtension" = $false
                                "isRequestorJustificationRequired" = $true
                                "approvalMode" = "SingleStage"
                                "approvalStages"= @(
                                    @{
                                        "approvalStageTimeOutInDays" = 1
                                        "isApproverJustificationRequired" = $true
                                        "escalationTimeInMinutes" = 0
                                        "primaryApprovers" = @()
                                        "isEscalationEnabled" = $false
                                    }
                                )
                            }
                            "id" = "Approval_EndUser_Assignment"
                            "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
                            "target" = @{
                                "caller" = "EndUser"
                                "operations" = @(
                                    "All"
                                )
                                "level" = "Assignment"
                                "inheritableSettings" = @()
                                "enforcedSettings" = @()
                            }
                        }
                        $rules += $activationApprover
                    }
                    "AzureResources" {
                        $activationApprover = [PSCustomObject]@{
                            
                            "setting"= @{
                                "isApprovalRequired" = $false
                                "isApprovalRequiredForExtension" = $false
                                "isRequestorJustificationRequired" = $true
                                "approvalMode" = "SingleStage"
                                "approvalStages"= @(
                                @{
                                    "approvalStageTimeOutInDays" = 1
                                    "isApproverJustificationRequired" = $true
                                    "escalationTimeInMinutes" = 0
                                    "isEscalationEnabled" = $false
                                }
                                )
                            }
                            "id" = "Approval_EndUser_Assignment"
                            "ruleType" = "RoleManagementPolicyApprovalRule"
                            "target" = @{
                                "caller" = "EndUser"
                                "operations" = @(
                                    "All"
                                )
                                "level" = "Assignment"
                            }
                        }
                        $rules += $activationApprover
                    }
                }
            }

            Add-Member -InputObject $result.DesiredConfiguration -MemberType NoteProperty -Name rules -Value $rules -Force

            switch ($resource.count) {
                0	{}
                1	{
                    $changes = @()

                    switch ($assignmentScope) {
                        "AzureAD" {
                            foreach ($rule in $result.DesiredConfiguration.rules) {
                                if (-not (Compare-PolicyProperties -ReferenceObject ($rule | ConvertTo-PSFHashtable) -DifferenceObject ($resource.value | Where-Object {$_.id -eq $rule.id} | ConvertTo-PSFHashtable))) {    
                                    $change = [PSCustomObject] @{
                                        Property = "rules"
                                        Actions = @{"Set" = $rule.id}
                                    }
                                    $changes += $change
                                }
                            }

                            if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
                            else { $result = New-TestResult @result -ActionType "NoActionRequired" }
                        }
                        "AzureResources" {
                            foreach ($rule in $result.DesiredConfiguration.rules) {
                                if (-not (Compare-PolicyProperties -ReferenceObject ($rule | ConvertTo-PSFHashtable) -DifferenceObject ($resource.properties.rules | Where-Object {$_.id -eq $rule.id} | ConvertTo-PSFHashtable))) {
                                    $change = [PSCustomObject] @{
                                        Property = "rules"
                                        Actions = @{"Set" = $rule.id}
                                    }
                                    $changes += $change
                                }
                            }
                            if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
                            else { $result = New-TestResult @result -ActionType "NoActionRequired" }
                        }
                    }

                    
                }
                default {
                    Write-PSFMessage -Level Warning -String 'AzurePIM.Test.MultipleResourcesError' -StringValues $resourceName, $result.ResourceName -Tag 'failed'
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
    end{}
}