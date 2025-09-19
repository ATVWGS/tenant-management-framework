
function Export-TmfRoleAssignment {
    <#
    .SYNOPSIS
    Exports role assignments (active and eligible) into TMF configuration objects or JSON.
    .DESCRIPTION
    Retrieves directory role assignments and eligibility schedules (optionally AzureResources/AADGroup scoping placeholder) and converts them to TMF shape including principal, role and scope metadata. Returns objects unless -OutPath is supplied.
    .PARAMETER SpecificResources
    Optional list of IDs, principal display names, or role definition display names (comma separated accepted) to filter.
    .PARAMETER Scope
    AzureResources | AzureAD | AADGroup (default AzureAD).
    .PARAMETER OutPath
    Root folder to write export; when omitted objects are returned.
    .PARAMETER ForceBeta
    Use beta Graph endpoint for retrieval (experimental; current retrieval uses directory scope endpoints).
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfRoleAssignment -Scope AzureAD -OutPath C:\temp\tmf
    .EXAMPLE
    Export-TmfRoleAssignment -Scope AzureResources -SpecificResources Owner
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
        $resourceName = 'roleAssignments'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $roleAssignmentsExport = @()
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleAssignment' -Message "Scope=$Scope ForceBeta=$ForceBeta"
        function Convert-RoleAssignment {
            param([object]$assignment, [string]$assignmentScope)
            $obj = [ordered]@{ present = $true }
            # Type
            if ($assignment -and $assignment.PSObject.Members.Match('assignmentState')) {
                $obj.type = $assignment.assignmentState.ToLower()
            } else {
                $obj.type = 'active'
            }
            # Principal reference/type
            if ($assignment.principal -and $assignment.principal.PSObject.Members.Match('displayName')) {
                $obj.principalReference = $assignment.principal.displayName
            }
            if ($assignment.principal) {
                switch ($assignment.principal.'@odata.type') {
                    '#microsoft.graph.user' {
                        $obj.principalType = 'user'
                    }
                    '#microsoft.graph.group' {
                        $obj.principalType = 'group'
                    }
                    '#microsoft.graph.servicePrincipal' {
                        $obj.principalType = 'servicePrincipal'
                    }
                    default {
                        $obj.principalType = 'user'
                    }
                }
            }
            # Role reference
            if ($assignment.roleDefinition -and $assignment.roleDefinition.PSObject.Members.Match('displayName')) {
                $obj.roleReference = $assignment.roleDefinition.displayName
            }
            # Scope mapping
            if ($assignmentScope -eq 'AzureResources') {
                if ($assignment.PSObject.Members.Match('directoryScopeId') -and $assignment.directoryScopeId) {
                    $scopeId = $assignment.directoryScopeId
                    if ($scopeId -match '/subscriptions/([^/]+)') {
                        $subId = $matches[1]; $obj.subscriptionReference = $subId
                        if ($scopeId -match '/subscriptions/[^/]+/resourceGroups/([^/]+)') {
                            $obj.scopeReference = $matches[1]; $obj.scopeType = 'resourceGroup'
                        } else {
                            $obj.scopeReference = $subId; $obj.scopeType = 'subscription'
                        }
                    }
                }
            } else {
                if ($assignment.PSObject.Members.Match('directoryScopeId') -and $assignment.directoryScopeId) {
                    $directoryScopeId = $assignment.directoryScopeId
                    if ($directoryScopeId -eq '/' -or $directoryScopeId -eq '') {
                        $obj.directoryScopeReference = '/'; $obj.directoryScopeType = 'directory'
                    } else {
                        $obj.directoryScopeReference = $directoryScopeId; $obj.directoryScopeType = 'administrativeUnit'
                    }
                } else {
                    $obj.directoryScopeReference = '/'; $obj.directoryScopeType = 'directory'
                }
            }
            # Schedule / expiration (null-safe)
            $obj.expirationType = 'noExpiration'
            if ($assignment.PSObject.Members.Match('scheduleInfo') -and $assignment.scheduleInfo) {
                $schedule = $assignment.scheduleInfo
                if ($schedule -and $schedule.PSObject.Members.Match('startDateTime') -and $schedule.startDateTime) {
                    $obj.startDateTime = $schedule.startDateTime
                }
                if ($schedule -and $schedule.PSObject.Members.Match('expiration') -and $schedule.expiration) {
                    $expiration = $schedule.expiration
                    if ($expiration -and $expiration.PSObject.Members.Match('type') -and $expiration.type) {
                        switch ($expiration.type) {
                            'noExpiration' {
                                $obj.expirationType = 'noExpiration'
                            }
                            'afterDateTime' {
                                $obj.expirationType = 'AfterDateTime'
                            }
                            'afterDuration' {
                                $obj.expirationType = 'AfterDuration'
                            }
                            default {
                                $obj.expirationType = $expiration.type
                            }
                        }
                    }
                    if ($expiration -and $expiration.PSObject.Members.Match('endDateTime') -and $expiration.endDateTime) {
                        $obj.endDateTime = $expiration.endDateTime
                    }
                    if ($expiration -and $expiration.PSObject.Members.Match('duration') -and $expiration.duration) {
                        $obj.duration = $expiration.duration
                    }
                }
            }
            return $obj
        }
        function Get-AllRoleAssignments {
            param([string]$assignmentScope)
            $apiBase = if ($ForceBeta) {
                $script:graphBaseUrlbeta
            } else {
                $script:graphBaseUrl1
            }
            $list = @()
            try {
                $activeResp = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/roleManagement/directory/roleAssignments?`$expand=principal" -ErrorAction Stop
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleAssignment' -Message "Active role assignments error: $($_.Exception.Message)"; $activeResp = @{value = @() }
            }
            try {
                $eligibleResp = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/roleManagement/directory/roleEligibilitySchedules?`$expand=principal" -ErrorAction Stop
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleAssignment' -Message "Eligible role assignments error: $($_.Exception.Message)"; $eligibleResp = @{value = @() }
            }
            $activeAssignments = @()
            foreach ($item in $activeResp.value) {
                try {
                    $roleDefResp = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/roleManagement/directory/roleDefinitions/$($item.roleDefinitionId)"; $item | Add-Member -MemberType NoteProperty -Name roleDefinition -Value $roleDefResp -Force
                } catch {
                }
                $item | Add-Member -MemberType NoteProperty -Name assignmentState -Value Active -Force; $activeAssignments += $item
            }
            $eligibleAssignments = @()
            foreach ($item in $eligibleResp.value) {
                try {
                    $roleDefResp = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/roleManagement/directory/roleDefinitions/$($item.roleDefinitionId)"; $item | Add-Member -MemberType NoteProperty -Name roleDefinition -Value $roleDefResp -Force
                } catch {
                }
                $item | Add-Member -MemberType NoteProperty -Name assignmentState -Value Eligible -Force; $eligibleAssignments += $item
            }
            foreach ($i in $activeAssignments) {
                $list += $i
            }
            foreach ($i in $eligibleAssignments) {
                $list += $i
            }
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleAssignment' -Message "Retrieved $($list.Count) role assignment records"
            return $list
        }
    }
    process {
        $assignmentScope = if ($Scope) {
            $Scope
        } else {
            'AzureAD'
        }
        if ($SpecificResources) {
            $identifiers = @()
            foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $identifiers = $identifiers | Select-Object -Unique
            $allRoleAssignments = Get-AllRoleAssignments -assignmentScope $assignmentScope
            foreach ($idOrName in $identifiers) {
                $match = $allRoleAssignments | Where-Object {
                    $_.id -eq $idOrName -or
                    ($_.principal -and $_.principal.displayName -eq $idOrName) -or
                    ($_.roleDefinition -and $_.roleDefinition.displayName -eq $idOrName)
                }
                if ($match) {
                    foreach ($m in $match) {
                        $convertedAssignment = Convert-RoleAssignment $m $assignmentScope
                        $roleAssignmentsExport += $convertedAssignment
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleAssignment' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName
                }
            }
        } else {
            $allRoleAssignments = Get-AllRoleAssignments -assignmentScope $assignmentScope
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleAssignment' -String 'TMF.Export.RetrievedResources' -StringValues ($allRoleAssignments.Count), $resourceName, $tenant.displayName

            foreach ($assignment in $allRoleAssignments) {
                $convertedAssignment = Convert-RoleAssignment $assignment $assignmentScope
                $roleAssignmentsExport += $convertedAssignment
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleAssignment' -Message "Exporting $($roleAssignmentsExport.Count) role assignment(s)"
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath'
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'roleManagement' -ResourceName $resourceName -Data $roleAssignmentsExport
        } else {
            return $roleAssignmentsExport
        }
    }
}
