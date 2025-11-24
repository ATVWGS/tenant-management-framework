<#
.SYNOPSIS
Exports accessPackages, accessPackageResources and accessPackageAssignmentPolicies into TMF configuration.
.DESCRIPTION
Retrieves access packages and referenced resources/assignmentPolicies and outputs TMF objects. Returns objects unless -OutPath supplied.
.PARAMETER SpecificResources
Optional list of setting IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned. (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAccessPackage -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfAccessPackage -SpecificResources AccessPackageName
#>
function Export-TmfAccessPackage {
    [CmdletBinding()] param(
        [string[]]$SpecificResources,
        [Alias('OutPutPath')] [string]$OutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessPackages'
        $base = ($script:graphBaseUrl -replace '/beta$', '/v1.0')
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id")).value
        $export = @()
        function Convert-Package {
            param($p)
            # Map expanded accessPackageResources into simplified objects
            $roleScopes = @()
            if ($p.resourceRoleScopes) {
                foreach ($rs in $p.resourceRoleScopes) {
                    $role = $rs.role
                    $scope = $rs.scope
                    $roleScopes += [ordered]@{
                        resourceRole       = $role.displayName
                        originSystem       = $role.originSystem
                        resourceType       = switch ($role.originSystem) {
                                             "AADGroup" {"AADGroup"}
                                             "AADApplication" {"Application"}
                                             "SharePointOnline" {"Sharepoint Online Site"}
                        }
                        resourceIdentifier = if ($role.originSystem -ne "SharePointOnline") {
                                                (Resolve-DirectoryObject -InputReference $scope.originId -ReturnObjects -DontFailIfNotExisting).displayName
                                             }
                                             else {
                                                $scope.originId
                                             }                        
                    }
                }
            }
            # Map expanded accessPackageAssignmentPolicies into simplified objects
            $assignmentPolicies = @()
            if ($p.assignmentPolicies) {
                foreach ($asp in $p.assignmentPolicies) {
                    $specificAllowedTargets = @()
                    foreach ($allowedTarget in $asp.specificAllowedTargets) {
                        $specificAllowedTargets += @{
                            reference = $allowedTarget.description
                            type = $allowedTarget."@odata.type".replace("#microsoft.graph.","")
                            description = $allowedTarget.description
                        }
                    }
                    if ($asp.requestApprovalSettings.stages) {
                        $stages = @()
                        foreach ($stage in $asp.requestApprovalSettings.stages) {
                            $primaryApprovers = @()
                            $fallbackPrimaryApprovers = @()
                            $escalationApprovers = @()
                            $fallbackEscalationApprovers = @()
                            if ($stage.primaryApprovers) {
                                foreach ($Approver in $stage.primaryApprovers) {
                                    switch ($Approver."@odata.type") {
                                        "#microsoft.graph.singleUser" {
                                            $primaryApprovers += @{
                                                reference = Resolve-User -InputReference $Approver.UserId -UserPrincipalName -DontFailIfNotExisting
                                                type = "singleUser"
                                            }
                                        }
                                        "#microsoft.graph.singleServicePrincipal" {
                                            $primaryApprovers += @{
                                                reference = Resolve-ServicePrincipal -InputReference $Approver.ServicePrincipalId -DisplayName -DontFailIfNotExisting
                                                type = "singleServicePrincipal"
                                            }
                                        }
                                        "#microsoft.graph.groupMembers" {
                                            $primaryApprovers += @{
                                                reference = Resolve-Group -InputReference $Approver.GroupId -DisplayName -DontFailIfNotExisting
                                                type = "groupMembers"
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            if ($stage.fallbackPrimaryApprovers) {
                                foreach ($Approver in $stage.fallbackPrimaryApprovers) {
                                    switch ($Approver."@odata.type") {
                                        "#microsoft.graph.singleUser" {
                                            $fallbackPrimaryApprovers += @{
                                                reference = Resolve-User -InputReference $Approver.UserId -UserPrincipalName -DontFailIfNotExisting
                                                type = "singleUser"
                                            }
                                        }
                                        "#microsoft.graph.singleServicePrincipal" {
                                            $fallbackPrimaryApprovers += @{
                                                reference = Resolve-ServicePrincipal -InputReference $Approver.ServicePrincipalId -DisplayName -DontFailIfNotExisting
                                                type = "singleServicePrincipal"
                                            }
                                        }
                                        "#microsoft.graph.groupMembers" {
                                            $fallbackPrimaryApprovers += @{
                                                reference = Resolve-Group -InputReference $Approver.GroupId -DisplayName -DontFailIfNotExisting
                                                type = "groupMembers"
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            if ($stage.escalationApprovers) {
                                foreach ($Approver in $stage.escalationApprovers) {
                                    switch ($Approver."@odata.type") {
                                        "#microsoft.graph.singleUser" {
                                            $escalationApprovers += @{
                                                reference = Resolve-User -InputReference $Approver.UserId -UserPrincipalName -DontFailIfNotExisting
                                                type = "singleUser"
                                            }
                                        }
                                        "#microsoft.graph.singleServicePrincipal" {
                                            $escalationApprovers += @{
                                                reference = Resolve-ServicePrincipal -InputReference $Approver.ServicePrincipalId -DisplayName -DontFailIfNotExisting
                                                type = "singleServicePrincipal"
                                            }
                                        }
                                        "#microsoft.graph.groupMembers" {
                                            $escalationApprovers += @{
                                                reference = Resolve-Group -InputReference $Approver.UserId -DisplayName -DontFailIfNotExisting
                                                type = "groupMembers"
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            if ($stage.fallbackEscalationApprovers) {
                                foreach ($Approver in $stage.fallbackEscalationApprovers) {
                                    switch ($Approver."@odata.type") {
                                        "#microsoft.graph.singleUser" {
                                            $fallbackEscalationApprovers += @{
                                                reference = Resolve-User -InputReference $Approver.UserId -UserPrincipalName -DontFailIfNotExisting
                                                type = "singleUser"
                                            }
                                        }
                                        "#microsoft.graph.singleServicePrincipal" {
                                            $fallbackEscalationApprovers += @{
                                                reference = Resolve-ServicePrincipal -InputReference $Approver.ServicePrincipalId -DisplayName -DontFailIfNotExisting
                                                type = "singleServicePrincipal"
                                            }
                                        }
                                        "#microsoft.graph.groupMembers" {
                                            $fallbackEscalationApprovers += @{
                                                reference = Resolve-Group -InputReference $Approver.UserId -DisplayName -DontFailIfNotExisting
                                                type = "groupMembers"
                                            }
                                        }
                                    }
                                    
                                }
                            }
                            $stage.primaryApprovers = $primaryApprovers
                            $stage.fallbackPrimaryApprovers = $fallbackPrimaryApprovers
                            $stage.escalationApprovers = $escalationApprovers
                            $stage.fallbackEscalationApprovers = $fallbackEscalationApprovers

                            $stages += $stage
                            
                        }
                        $asp.requestApprovalSettings.stages = $stages
                    }
                    if (-not $specificAllowedTargets) {
                        $assignmentPolicies += [ordered]@{
                            displayname             = $asp.displayName
                            description             = $asp.description
                            allowedTargetScope      = $asp.allowedTargetScope
                            expiration              = $asp.expiration
                            requestorSettings       = $asp.requestorSettings
                            requestApprovalSettings = $asp.requestApprovalSettings
                            present                 = $true
                        }
                    }
                    else {
                        $assignmentPolicies += [ordered]@{
                            displayname             = $asp.displayName
                            description             = $asp.description
                            allowedTargetScope      = $asp.allowedTargetScope
                            specificAllowedTargets  = $specificAllowedTargets
                            expiration              = $asp.expiration
                            requestorSettings       = $asp.requestorSettings
                            requestApprovalSettings = $asp.requestApprovalSettings
                            present                 = $true
                        }
                    }                    
                }
            }
            # Get catalogName
            $catalogName = $null
            if ($p.catalog -and $p.catalog.displayName) {
                $catalogName = $p.catalog.displayName 
            } elseif ($p.catalog.Id) {
                $catalogName = $p.catalog.Id 
            }
            [ordered]@{
                displayName                     = $p.displayName
                description                     = $p.description
                isHidden                        = $p.isHidden
                catalog                         = $catalogName
                accessPackageResources          = $roleScopes
                assignmentPolicies              = $assignmentPolicies
                present                         = $true
            }
        }
        function Get-AllPackages {
            $list = @()
            $expand = 'assignmentPolicies,resourceRoleScopes($expand=*),catalog'
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/accessPackages?`$top=50&`$expand=$expand" -ErrorAction Stop
                if ($resp.'@odata.nextLink') {
                    do {
                        $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                    } while ($resp.'@odata.nextLink') 
                } else {
                    $list += $resp.value 
                }
                return $list
            } catch {
                $initialError = $_.Exception.Message
                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessPackage' -Message "Expanded retrieval failed ($initialError). Falling back to minimal retrieval then per-package expansion."
                # Fallback: retrieve packages without expand
                try {
                    $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/accessPackages?`$top=50" -ErrorAction Stop
                } catch {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackage' -Message "Fallback minimal retrieval failed: $($_.Exception.Message)"; return $list
                }
                $minimal = @(); if ($resp.'@odata.nextLink') {
                    do {
                        $minimal += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                    } while ($resp.'@odata.nextLink') 
                } else {
                    $minimal += $resp.value 
                }
                foreach ($pkg in $minimal) {
                    $detail = $null
                    try {
                        $detail = Invoke-MgGraphRequest -Method GET -Uri ("$base/identityGovernance/entitlementManagement/accessPackages/{0}?`$expand={1}" -f $pkg.id, $expand) -ErrorAction Stop
                        $list += $detail
                    } catch {
                        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAccessPackage' -Message ("Per-package expand failed for {0}: {1}. Using minimal object." -f $pkg.displayName, $_.Exception.Message)
                        $list += $pkg
                    }
                }
                return $list
            }
        }
        $all = Get-AllPackages
    }
    process {
        if ($SpecificResources) {
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique
            foreach ($id in $ids) {
                $match = $all | Where-Object displayName -EQ $id; if ($match) {
                    $match | ForEach-Object { $export += Convert-Package $_ } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackage' -String 'TMF.Export.NotFound' -StringValues $id, $resourceName, $tenant.displayName 
                } 
            }
        } else {
            foreach ($p in $all) {
                $export += Convert-Package $p 
            } 
        }
    }
    end {
        if ($OutPath) {
            if ($export) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export
                }
            }            
        } else {
            return $export 
        }
    }
}
