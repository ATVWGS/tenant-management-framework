function Export-TmfRoleManagement {
    <#
    .SYNOPSIS
    Exports all role management resources (assignments, definitions, policies) into TMF configuration JSON.
    .DESCRIPTION
    Invokes individual role management export functions for roleAssignments, roleDefinitions and roleManagementPolicies using optional scope and resource filtering. Returns nothing unless -OutPath is omitted; subordinate functions handle object returns.
    .PARAMETER Scope
    AzureResources | AzureAD | AADGroup. Passed to underlying role exports.
    .PARAMETER SpecificResources
    Optional list of IDs or display names (comma separated accepted) passed through to underlying role export functions.
    .PARAMETER OutPath
    Root folder to write export output. When omitted, underlying functions return objects (this wrapper does not aggregate them).
    .PARAMETER ForceBeta
    Use beta Graph endpoint for underlying exports.
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfRoleManagement -Scope AzureAD -OutPath C:\temp\tmf
    .EXAMPLE
    Export-TmfRoleManagement -Scope AzureResources -SpecificResources Owner
    NOTE: Parameter `-OutPutPath` is deprecated; retained as alias.
    #>

    [CmdletBinding()] param(
        [ValidateSet('AzureResources', 'AzureAD', 'AADGroup')] [string] $Scope,
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/organization?`$select=displayname,id")).value
        if ($tenant) {
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleManagement' -Message "Tenant: $($tenant.displayName) ($($tenant.id))"
        }
        $roleManagementResources = @('roleAssignments', 'roleDefinitions', 'roleManagementPolicies')
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleManagement' -Message "Preparing export for: $($roleManagementResources -join ', ') ForceBeta=$ForceBeta"
    }
    process {
        foreach ($resourceType in $roleManagementResources) {
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleManagement' -Message "Exporting $resourceType"
            $exportParams = @{ OutPath = $OutPath; Cmdlet = $Cmdlet }
            if ($Scope) {
                $exportParams.Scope = $Scope
            }
            if ($SpecificResources) {
                $exportParams.SpecificResources = $SpecificResources
            }
            if ($ForceBeta) {
                $exportParams.ForceBeta = $true
            }
            switch ($resourceType) {
                'roleAssignments' {
                    Export-TmfRoleAssignment       @exportParams
                }
                'roleDefinitions' {
                    Export-TmfRoleDefinition       @exportParams
                }
                'roleManagementPolicies' {
                    Export-TmfRoleManagementPolicy @exportParams
                }
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfRoleManagement' -Message 'Role management export complete.'
    }
}
