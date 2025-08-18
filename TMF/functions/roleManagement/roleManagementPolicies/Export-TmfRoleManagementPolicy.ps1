<#
.SYNOPSIS
Exports role management policies into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves role management policies (directory or Azure resource placeholder) including rules and role references. Returns objects unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional list of policy IDs, display names, or associated role display names (comma separated accepted) to filter.
.PARAMETER Scope
AzureResources | AzureAD | AADGroup (default AzureAD).
.PARAMETER OutPutPath
Root folder to write export; when omitted objects are returned.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfRoleManagementPolicy -Scope AzureAD -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfRoleManagementPolicy -SpecificResources 'Privileged Role Administrator'
#>
function Export-TmfRoleManagementPolicy {
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [ValidateSet('AzureResources','AzureAD','AADGroup')] [string] $Scope,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'roleManagementPolicies'
    $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
    $v1Base    = $script:graphBaseUrl1
    $betaBase  = $script:graphBaseUrl
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/organization?`$select=displayname,id")).value
        $roleManagementPoliciesExport = @()
        function Convert-RoleManagementPolicy { param([object]$policy,[string]$policyScope)
            $obj=[ordered]@{present=$true}
            if ($policy.PSObject.Members.Match('displayName') -and $policy.displayName) { $obj.displayName=$policy.displayName }
            if ($policy.PSObject.Members.Match('description') -and $policy.description) { $obj.description=$policy.description }
            if ($policy.PSObject.Members.Match('id') -and $policy.id) { $obj.id=$policy.id }
            if ($policy.PSObject.Members.Match('isOrganizationDefault')) { $obj.isOrganizationDefault=$policy.isOrganizationDefault }
            if ($policy.roleDefinition -and $policy.roleDefinition.PSObject.Members.Match('displayName')) { $obj.roleReference=$policy.roleDefinition.displayName }
            $obj.activationApprover=@()
            if ($policy.PSObject.Members.Match('rules')) {
                # Derive approval rules irrespective of property naming differences
                $approverRules=$policy.rules | Where-Object {
                    ($_.PSObject.Members.Match('ruleType') -and $_.ruleType -match 'Approval') -or
                    ($_.PSObject.Members.Match('@odata.type') -and $_.'@odata.type' -match 'unifiedRoleManagementPolicyApprovalRule')
                }
                foreach ($rule in $approverRules) {
                    if ($rule.PSObject.Members.Match('setting') -and $rule.setting.PSObject.Members.Match('approvalStages')) {
                        foreach ($stage in $rule.setting.approvalStages) {
                            if ($stage.primaryApprovers) {
                                foreach ($approver in $stage.primaryApprovers) {
                                    $obj.activationApprover += [ordered]@{reference=$approver.displayName;type=($approver.'@odata.type' -replace '#microsoft.graph.','')}
                                }
                            }
                        }
                    }
                }
            }
            if ($policy.PSObject.Members.Match('rules')) {
                $obj.rules=@()
                foreach ($rule in $policy.rules) {
                    if ($rule.PSObject.Members.Match('id')) {
                        $derivedRuleType = if ($rule.PSObject.Members.Match('ruleType')) { $rule.ruleType } elseif ($rule.PSObject.Members.Match('@odata.type')) { ($rule.'@odata.type' -replace '#microsoft.graph.','') } else { $null }
                        $r=[ordered]@{id=$rule.id}
                        if ($derivedRuleType) { $r.ruleType=$derivedRuleType }
                        if ($rule.PSObject.Members.Match('target')) { $r.target=$rule.target }
                        if ($rule.PSObject.Members.Match('setting')) { $r.setting=$rule.setting }
                        $obj.rules += $r
                    }
                }
            }
            if ($policy.PSObject.Members.Match('scopeId')) { $obj.scopeId=$policy.scopeId }
            if ($policy.PSObject.Members.Match('scopeType')) { $obj.scopeType=$policy.scopeType }
            if ($policyScope -eq 'AzureResources') {
                if ($policy.PSObject.Members.Match('scopeId')) {
                    $scopeParts=$policy.scopeId -split '/'
                    if ($scopeParts.Count -ge 3 -and $scopeParts[1] -eq 'subscriptions') {
                        $obj.subscriptionReference=$scopeParts[2]
                        if ($scopeParts.Count -ge 5 -and $scopeParts[3] -eq 'resourceGroups') {
                            $obj.scopeReference=$scopeParts[4]; $obj.scopeType='resourceGroup'
                        } else { $obj.scopeReference=$scopeParts[2]; $obj.scopeType='subscription' }
                    }
                }
            } else {
                if (-not ($obj.PSObject.Members.Match('scopeId')) -or $obj.scopeId -eq '/') { $obj.scopeReference='/'; $obj.scopeType='directory' }
            }
            return $obj
        }
        function Get-AllRoleManagementPolicies { param([string]$policyScope,[string[]]$GroupIds)
            $collected=@(); $usedBase=$graphBase
            $attempts=@($graphBase); if (-not $ForceBeta -and $graphBase -ne $betaBase) { $attempts+= $betaBase }
            # Build required filters based on scope as per Microsoft Docs (List roleManagementPolicies)
            $filters=@()
            switch ($policyScope) {
                'AzureAD' { $filters += "scopeId eq '/' and scopeType eq 'DirectoryRole'"; $filters += "scopeId eq '/' and scopeType eq 'Directory'" }
                'AzureResources' { $filters += "scopeType eq 'AzureResource'" } # placeholder – actual Azure RBAC policies are different API set
                'AADGroup' {
                    if ($GroupIds) { foreach ($gid in $GroupIds) { $filters += "scopeId eq '$gid' and scopeType eq 'Group'" } }
                    else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleManagementPolicy' -Message 'Group scope requested but no group IDs supplied via -SpecificResources; no policies will be returned.' }
                }
                default { $filters += "scopeId eq '/' and scopeType eq 'DirectoryRole'" }
            }
            foreach ($baseAttempt in $attempts) {
                foreach ($filter in $filters) {
                    try {
                        $uri = "$baseAttempt/policies/roleManagementPolicies?`$filter=$([uri]::EscapeDataString($filter))&`$expand=rules"
                        $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
                        if ($resp.value) { $collected += $resp.value }
                        while ($resp.'@odata.nextLink') {
                            $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' -ErrorAction Stop
                            if ($resp.value) { $collected += $resp.value }
                        }
                    }
                    catch {
                        Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleManagementPolicy' -Message ("List policies error (base={0} filter=<{1}>): {2}" -f $baseAttempt,$filter,$_.Exception.Message)
                    }
                }
                if ($collected.Count) { if ($baseAttempt -ne $graphBase) { Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleManagementPolicy' -Message 'Fell back to beta endpoint for roleManagementPolicies.' }; break }
            }
            return ($collected | Sort-Object -Property id -Unique)
        }
    }
    process {
        $policyScope = if ($Scope) { $Scope } else { 'AzureAD' }
        
        if ($SpecificResources) {
            $identifiers = @()
            foreach ($entry in $SpecificResources) { $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
            $identifiers = $identifiers | Select-Object -Unique
            $allRoleManagementPolicies = Get-AllRoleManagementPolicies -policyScope $policyScope
            foreach ($idOrName in $identifiers) {
                $match = $allRoleManagementPolicies | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName -or $_.roleDefinition.displayName -eq $idOrName }
                if ($match) { foreach ($m in $match) { $roleManagementPoliciesExport += Convert-RoleManagementPolicy $m $policyScope } }
                else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleManagementPolicy' -String 'TMF.Export.NotFound' -StringValues $idOrName,$resourceName,$tenant.displayName }
            }
        } else {
            $allRoleManagementPolicies = Get-AllRoleManagementPolicies -policyScope $policyScope
            foreach ($policy in $allRoleManagementPolicies) {
                $roleManagementPoliciesExport += Convert-RoleManagementPolicy $policy $policyScope
            }
        }

        if (-not $OutPutPath) { return $roleManagementPoliciesExport }
    }
    end {
        if ($OutPutPath) {
            $targetDir = Join-Path -Path $OutPutPath -ChildPath "roleManagement/$resourceName"
            if (-not (Test-Path -LiteralPath $targetDir)) { if (-not (Test-Path -LiteralPath (Join-Path $OutPutPath 'roleManagement'))) { New-Item -Path $OutPutPath -Name roleManagement -ItemType Directory -Force | Out-Null }; New-Item -Path (Join-Path $OutPutPath 'roleManagement') -Name $resourceName -ItemType Directory -Force | Out-Null }
            $roleManagementPoliciesExport | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir "$resourceName.json") -Encoding utf8 -Force
        }
    }
}
