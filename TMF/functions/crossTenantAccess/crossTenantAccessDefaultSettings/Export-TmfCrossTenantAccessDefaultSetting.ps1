<#
.SYNOPSIS
Exports cross-tenant access default settings into TMF configuration.
.DESCRIPTION
Retrieves the crossTenantAccessPolicy default settings (v1.0 unless ForceBeta) and maps key properties to a TMF object. Returns object unless -OutPath supplied. (Legacy alias: -OutPutPath)
.PARAMETER OutPath
Root folder to write export; when omitted object is returned. (Legacy alias: -OutPutPath)
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCrossTenantAccessDefaultSetting -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfCrossTenantAccessDefaultSetting | ConvertTo-Json -Depth 15
#>
function Export-TmfCrossTenantAccessDefaultSetting {
    [CmdletBinding()] param(
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessDefaultSettings'
        $graphBase = if ($ForceBeta) {
            $script:graphBaseUrl 
        } else {
            $script:graphBaseUrl1 
        }
        $setting = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/policies/crossTenantAccessPolicy/default"
    }
    process {
        foreach ($prop in '@odata.context', 'id', '@odata.etag', 'policyTenantId', 'tenantGroup', 'supportedClouds', 'migrationStatus', 'version', 'lastModifiedDateTime', 'applyDefaultsToDomainBasedOrganizations') {
            $setting.PSObject.Properties.Remove($prop) | Out-Null 
        }
        $export = [ordered]@{
            displayName                                       = 'CrossTenantAccessDefaultSettings'
            inboundTrust                                      = $setting.inboundTrust
            automaticUserConsentSettings                      = $setting.automaticUserConsentSettings
            b2bCollaborationOutbound                          = $setting.b2bCollaborationOutbound
            b2bCollaborationInbound                           = $setting.b2bCollaborationInbound
            b2bDirectConnectOutbound                          = $setting.b2bDirectConnectOutbound
            b2bDirectConnectInbound                           = $setting.b2bDirectConnectInbound
            invitationRedemptionIdentityProviderConfiguration = $setting.invitationRedemptionIdentityProviderConfiguration
            tenantRestrictions                                = $setting.tenantRestrictions
            present                                           = $true
        }
        if ($setting.PSObject.Properties['isServiceDefault']) {
            $export.isServiceDefault = $setting.isServiceDefault 
        }
    }
    end {
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath' 
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'crossTenantAccess' -ResourceName $resourceName -Data @($export)
        } else {
            return $export
        }
    }
}
