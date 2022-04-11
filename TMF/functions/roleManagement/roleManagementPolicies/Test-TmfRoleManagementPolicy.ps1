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
                    $resource += (Invoke-RestMethod -Method "GET" -Uri "https://management.azure.com/providers/Microsoft.Subscription$($policyId)?api-version=2020-10-01-preview" -Headers @{"Authorization" = "Bearer $($token)"}).properties.rules

                    $result["AzureResource"] = $resource
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
                    $resource = @()
                    $resource += (Invoke-MgGraphRequest -Method "GET" -Uri "$($script:graphBaseUrl)/policies/roleManagementPolicies/DirectoryRole_$($tenant.Id)_$($roleId)/rules").value
                    
                    $result["GraphResource"] = $resource
                }
            }
            
            $rules = @()
            $rules += ($script:desiredConfiguration["roleManagementPolicyRuleTemplates"] | Where-Object {$_.displayName -eq $definition.ruleTemplate}).rules

            if ($definition.activationApprover) {
                
                $primaryApprovers = @()
                foreach ($item in $definition.activationApprover) {

                    switch ($item.type) {
                        "user" {
                            $referenceID = Resolve-User -InputReference $item.reference
                            $primaryApprovers += @{
                                "id" = $referenceID
                                "description" = $item.reference
                                "isBackup" = $false
                                "userType" = "User"
                            }

                            
                        }
                        "group" {
                            $referenceID = Resolve-Group -InputReference $item.reference
                            $primaryApprovers += @{
                                "id" = $referenceID
                                "description" = $item.reference
                                "isBackup" = $false
                                "userType" = "Group"
                            }
                        }
                    }
                }    
                $activationApprover = @{
                            
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
            
            $result["rules"] = $rules
        }




        $result
    }

    end{}
}