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
            # Map expanded accessPackageResourceRoleScopes into simplified objects
            $roleScopes = @()
            if ($p.accessPackageResourceRoleScopes) {
                foreach ($rs in $p.accessPackageResourceRoleScopes) {
                    $role = $rs.accessPackageResourceRole
                    $scope = $rs.accessPackageResourceScope
                    $roleScopes += [ordered]@{
                        roleDisplayName = $role.displayName
                        roleOriginId    = $role.originId
                        resourceId      = $role.resource.id
                        scopeType       = $scope.scopeType
                        scopeId         = $scope.id
                        scopeOriginId   = $scope.originId
                        createdDateTime = $rs.createdDateTime
                    }
                }
            }
            $catalogName = $null
            if ($p.accessPackageCatalog -and $p.accessPackageCatalog.displayName) {
                $catalogName = $p.accessPackageCatalog.displayName 
            } elseif ($p.accessPackageCatalog.Id) {
                $catalogName = $p.accessPackageCatalog.Id 
            }
            [ordered]@{
                displayName                     = $p.displayName
                description                     = $p.description
                isHidden                        = $p.isHidden
                isRoleScopesVisible             = $p.isRoleScopesVisible
                catalog                         = $catalogName
                accessPackageResourceRoleScopes = $roleScopes
                present                         = $true
            }
        }
        function Get-AllPackages {
            $list = @()
            $expand = 'accessPackageResourceRoleScopes($expand=*),accessPackageCatalog'
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackages?`$top=50&`$expand=$expand" -ErrorAction Stop
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
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath' 
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export
        } else {
            return $export 
        }
    }
}
