function Export-TmfRoleManagementPolicy {
    <#
    .SYNOPSIS
    Exports role management policies (PIM) into TMF configuration objects or JSON.
    .DESCRIPTION
    Retrieves role management policy assignments and policies (directory scope only) and converts them to TMF shape including rules. Returns objects unless -OutPath is supplied.
    .PARAMETER SpecificResources
    Optional list of policy assignment IDs or role definition display names (comma separated accepted) to filter.
    .PARAMETER Scope
    AzureResources | AzureAD | AADGroup (default AzureAD).
    .PARAMETER OutPath
    Root folder to write export; when omitted objects are returned.
    .PARAMETER ForceBeta
    Use beta Graph endpoint for retrieval.
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfRoleManagementPolicy -Scope AzureAD -OutPath C:\temp\tmf
    .EXAMPLE
    Export-TmfRoleManagementPolicy -Scope AzureResources -SpecificResources Global Reader
    NOTE: Parameter `-OutPutPath` is deprecated; retained as alias.
    #>

    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [ValidateSet('AzureResources', 'AzureAD', 'AADGroup')] [string] $Scope,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'roleManagementPolicies'
        $templateName = 'roleManagementPolicyRuleTemplates'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $roleManagementPoliciesExport = @()
        $roleManagementPolicyRuleTemplatesExport = @()
        function Convert-RoleManagementPolicy {
            param([object]$policy, [string]$policyScope)
            $obj = [ordered]@{present = $true }
            if ($policy.PSObject.Members.Match('id') -and $policy.id) {
                $roleId = (Invoke-MgGraphRequest -Method "GET" -Uri "$($script:graphBaseUrl)/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '/' and scopeType eq 'Directory' and policyId eq '$($policy.id)'").value.roleDefinitionId
                $obj.roleReference = Resolve-DirectoryRoleDefinition -InputReference $roleId -DisplayName
            }
            $obj.activationApprover = @()
            if ($policy.PSObject.Members.Match('rules')) {
                # Derive approval rules irrespective of property naming differences
                $approverRules = $policy.rules | Where-Object {
                    ($_.PSObject.Members.Match('ruleType') -and $_.ruleType -match 'Approval') -or
                    ($_.PSObject.Members.Match('@odata.type') -and $_.'@odata.type' -match 'unifiedRoleManagementPolicyApprovalRule')
                }
                foreach ($rule in $approverRules) {
                    if ($rule.PSObject.Members.Match('setting') -and $rule.setting.PSObject.Members.Match('approvalStages')) {
                        foreach ($stage in $rule.setting.approvalStages) {
                            if ($stage.primaryApprovers) {
                                foreach ($approver in $stage.primaryApprovers) {
                                    if ($approver.userId) {
                                        $reference = Resolve-User -InputReference $approver.userId -UserPrincipalName
                                    }
                                    else {
                                        $reference = Resolve-Group -InputReference $approver.groupId -DisplayName
                                    }
                                    $obj.activationApprover += [ordered]@{reference = $reference; type = ($approver.'@odata.type' -replace '#microsoft.graph.', '') }
                                }
                            }
                        }
                    }
                }
            }
            if ($policy.PSObject.Members.Match('scopeId')) {
                $obj.scopeId = $policy.scopeId
            }
            if ($policy.PSObject.Members.Match('scopeType')) {
                $obj.scopeType = $policy.scopeType
            }
            if ($policyScope -eq 'AzureResources') {
                if ($policy.PSObject.Members.Match('scopeId')) {
                    $scopeParts = $policy.scopeId -split '/'
                    if ($scopeParts.Count -ge 3 -and $scopeParts[1] -eq 'subscriptions') {
                        $obj.subscriptionReference = $scopeParts[2]
                        if ($scopeParts.Count -ge 5 -and $scopeParts[3] -eq 'resourceGroups') {
                            $obj.scopeReference = $scopeParts[4]; $obj.scopeType = 'resourceGroup'
                        } else {
                            $obj.scopeReference = $scopeParts[2]; $obj.scopeType = 'subscription'
                        }
                    }
                }
            } else {
                if (-not ($obj.PSObject.Members.Match('scopeId')) -or $obj.scopeId -eq '/') {
                    $obj.scopeReference = '/'; $obj.scopeType = 'directory'
                }
            }
            if ($policy.PSObject.Members.Match('rules')) {
                $templateObj = [ordered]@{displayName = "$($obj.roleReference.replace(' ',''))_$($policy.scopeType)" }
                $templateObj.rules = @()
                foreach ($rule in $policy.rules) {
                    if ($rule.PSObject.Members.Match('id') -and $rule.id -ne 'Approval_EndUser_Assignment') {
                        $templateObj.rules += $rule
                    }
                }
                $obj.ruleTemplate = $templateObj.displayName
            }
            
            if ($templateObj) {
                return $obj,$templateObj
            }
            else {
                return $obj
            }            
        }
        
        function Get-AllRoleManagementPolicies {
            param([string]$policyScope, [string[]]$GroupIds)
            $collected = @()
            $primaryBase = if ($ForceBeta) {
                $script:graphBaseUrlbeta
            } else {
                $script:graphBaseUrl1
            }
            $attempts = @($primaryBase); if (-not $ForceBeta) {
                $attempts += $script:graphBaseUrlbeta
            }
            # Build required filters based on scope as per Microsoft Docs (List roleManagementPolicies)
            $filters = @()
            switch ($policyScope) {
                'AzureAD' {
                    #$filters += "scopeId eq '/' and scopeType eq 'DirectoryRole'"; 
                    $filters += "scopeId eq '/' and scopeType eq 'Directory'"
                }
                'AzureResources' {
                    $filters += "scopeType eq 'AzureResource'"
                } # placeholder – actual Azure RBAC policies are different API set
                'AADGroup' {
                    if ($GroupIds) {
                        foreach ($gid in $GroupIds) {
                            $filters += "scopeId eq '$gid' and scopeType eq 'Group'"
                        }
                    } else {
                        Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleManagementPolicy' -Message 'Group scope requested but no group IDs supplied via -SpecificResources; no policies will be returned.'
                    }
                }
                default {
                    $filters += "scopeId eq '/' and scopeType eq 'DirectoryRole'"
                }
            }
            foreach ($baseAttempt in $attempts) {
                foreach ($filter in $filters) {
                    try {
                        $uri = "$baseAttempt/policies/roleManagementPolicies?`$filter=$([uri]::EscapeDataString($filter))&`$expand=rules"
                        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                        if ($resp.value) {
                            $collected += $resp.value
                        }
                        while ($resp.'@odata.nextLink') {
                            $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' -ErrorAction Stop
                            if ($resp.value) {
                                $collected += $resp.value
                            }
                        }
                    } catch {
                        Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleManagementPolicy' -Message ("List policies error (base={0} filter=<{1}>): {2}" -f $baseAttempt, $filter, $_.Exception.Message)
                    }
                }
                if ($collected.Count) {
                    if ($baseAttempt -ne $primaryBase) {
                        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleManagementPolicy' -Message 'Fell back to beta endpoint for roleManagementPolicies.'
                    }; break
                }
            }
            return ($collected | Sort-Object -Property id -Unique)
        }
    }
    process {
        if ($Scope -and ($Scope -ne "AzureAD")) {
            $policyScope = 'AzureAD'
            Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleAssignment' -String 'TMF.Export.ScopeNotSupported' -StringValues $Scope,$resourceName,$policyScope
        } else {
            $policyScope = 'AzureAD'
        }

        if ($SpecificResources) {
            $identifiers = @()
            foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $identifiers = $identifiers | Select-Object -Unique
            $allRoleManagementPolicies = Get-AllRoleManagementPolicies -policyScope $policyScope
            foreach ($idOrName in $identifiers) {
                $match = $allRoleManagementPolicies | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName -or $_.roleDefinition.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) {
                        $result = Convert-RoleManagementPolicy $m $policyScope
                        if ($result.count -eq 2) {
                            $roleManagementPoliciesExport += $result[0]
                            $roleManagementPolicyRuleTemplatesExport += $result[1]
                        }
                        else {
                            $roleManagementPoliciesExport += $result
                        }
                        #$roleManagementPoliciesExport += Convert-RoleManagementPolicy $m $policyScope
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleManagementPolicy' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName
                }
            }
        } else {
            $allRoleManagementPolicies = Get-AllRoleManagementPolicies -policyScope $policyScope
            foreach ($policy in $allRoleManagementPolicies) {
                $result = Convert-RoleManagementPolicy $policy $policyScope
                if ($result.count -eq 2) {
                    $roleManagementPoliciesExport += $result[0]
                    $roleManagementPolicyRuleTemplatesExport += $result[1]
                }
                else {
                    $roleManagementPoliciesExport += $result
                }
                #$roleManagementPoliciesExport += Convert-RoleManagementPolicy $policy $policyScope
            }
        }
    }
    end {
        if (-not $OutPath) {
            return $roleManagementPoliciesExport
        }
        Write-TmfExportFile -OutPath $OutPath -ParentPath 'roleManagement' -ResourceName $resourceName -Data $roleManagementPoliciesExport
        if ($roleManagementPolicyRuleTemplatesExport) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'roleManagement' -ResourceName $templateName -Data $roleManagementPolicyRuleTemplatesExport
        }
    }
}
