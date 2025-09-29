
function Export-TmfRoleDefinition {
    <#
    .SYNOPSIS
    Exports role definitions into TMF configuration objects or JSON.
    .DESCRIPTION
    Retrieves directory (or Azure resource placeholder) role definitions and converts them to TMF shape including metadata, permissions and scopes. Returns objects unless -OutPath is supplied.
    .PARAMETER SpecificResources
    Optional list of role definition IDs or display names (comma separated accepted) to filter.
    .PARAMETER Scope
    AzureResources | AzureAD | AADGroup (default AzureAD).
    .PARAMETER OutPath
    Root folder to write export; when omitted objects are returned.
    .PARAMETER ForceBeta
    Use beta Graph endpoint for retrieval.
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfRoleDefinition -Scope AzureAD -OutPath C:\temp\tmf
    .EXAMPLE
    Export-TmfRoleDefinition -SpecificResources Global* | ConvertTo-Json -Depth 15
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
        $resourceName = 'roleDefinitions'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $roleDefinitionsExport = @()
        function Convert-RoleDefinition {
            param([object]$roleDef, [string]$definitionScope) $obj = [ordered]@{present = $true; displayName = $roleDef.displayName }; if ($roleDef.PSObject.Members.Match('description') -and $roleDef.description) {
                $obj.description = $roleDef.description
            }; if ($roleDef.PSObject.Members.Match('id') -and $roleDef.id) {
                $obj.id = $roleDef.id
            }; if ($roleDef.PSObject.Members.Match('isBuiltIn')) {
                $obj.isBuiltIn = $roleDef.isBuiltIn
            }; if ($roleDef.PSObject.Members.Match('isEnabled')) {
                $obj.isEnabled = $roleDef.isEnabled
            }; if ($roleDef.PSObject.Members.Match('templateId') -and $roleDef.templateId) {
                $obj.templateId = $roleDef.templateId
            }; if ($roleDef.PSObject.Members.Match('version') -and $roleDef.version) {
                $obj.version = $roleDef.version
            }; if ($roleDef.PSObject.Members.Match('allowedPrincipalTypes') -and $roleDef.allowedPrincipalTypes) {
                $obj.allowedPrincipalTypes = $roleDef.allowedPrincipalTypes
            }; if ($definitionScope -eq 'AzureResources') {
                if ($roleDef.PSObject.Members.Match('assignableScopes') -and $roleDef.assignableScopes) {
                    $obj.assignableScopes = $roleDef.assignableScopes; $subscriptionScope = $roleDef.assignableScopes | Where-Object { $_ -match '/subscriptions/([^/]+)' }; if ($subscriptionScope) {
                        $subId = ($subscriptionScope | Select-Object -First 1) -replace '.*\/subscriptions\/([^\/]+).*', '$1'; $obj.subscriptionReference = $subId
                    }
                }; if ($roleDef.PSObject.Members.Match('permissions') -and $roleDef.permissions) {
                    $obj.permissions = $roleDef.permissions
                }
            } else {
                if ($roleDef.PSObject.Members.Match('rolePermissions') -and $roleDef.rolePermissions) {
                    $obj.rolePermissions = $roleDef.rolePermissions
                }; if ($roleDef.PSObject.Members.Match('resourceScopes') -and $roleDef.resourceScopes) {
                    $obj.resourceScopes = $roleDef.resourceScopes
                }; if ($roleDef.PSObject.Members.Match('isPrivileged')) {
                    $obj.isPrivileged = $roleDef.isPrivileged
                }
            }; return $obj
        }
        function Get-AllRoleDefinitions {
            param([string]$definitionScope)
            $base = if ($ForceBeta) {
                $script:graphBaseUrlbeta
            } else {
                $script:graphBaseUrl1
            }
            $list = @(); $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/roleManagement/directory/roleDefinitions?`$filter=isBuiltIn eq false"; if ($resp.keys -contains '@odata.nextLink') {
                do {
                    $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink'
                } while ($resp.'@odata.nextLink')
            } else {
                $list += $resp.value
            }; return $list
        }
    }
    process {
        if ($Scope -and ($Scope -ne "AzureAD")) {
            $definitionScope = 'AzureAD'
            Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleAssignment' -String 'TMF.Export.ScopeNotSupported' -StringValues $Scope,$resourceName,$definitionScope
        } else {
            $definitionScope = 'AzureAD'
        }

        if ($SpecificResources) {
            $identifiers = @()
            foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $identifiers = $identifiers | Select-Object -Unique
            $allRoleDefinitions = Get-AllRoleDefinitions -definitionScope $definitionScope
            foreach ($idOrName in $identifiers) {
                $match = $allRoleDefinitions | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) {
                        $roleDefinitionsExport += Convert-RoleDefinition $m $definitionScope
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfRoleDefinition' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName
                }
            }
        } else {
            $allRoleDefinitions = Get-AllRoleDefinitions -definitionScope $definitionScope
            foreach ($roleDef in $allRoleDefinitions) {
                $roleDefinitionsExport += Convert-RoleDefinition $roleDef $definitionScope
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleDefinition' -Message "Exporting $($roleDefinitionsExport.Count) role definition(s)"
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'roleManagement' -ResourceName $resourceName -Data $roleDefinitionsExport
        } else {
            return $roleDefinitionsExport
        }
    }
}
