<#
.SYNOPSIS
Exports cross-tenant access default settings into TMF configuration.
.DESCRIPTION
Retrieves the crossTenantAccessPolicy default settings (v1.0 unless ForceBeta) and maps key properties to a TMF object. Returns object unless -OutPutPath supplied.
.PARAMETER OutPutPath
Root folder to write export; when omitted object is returned.
.PARAMETER ForceBeta
Use beta endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCrossTenantAccessDefaultSetting -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfCrossTenantAccessDefaultSetting | ConvertTo-Json -Depth 15
#>
function Export-TmfCrossTenantAccessDefaultSetting {
    [CmdletBinding()] Param(
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessDefaultSettings'
        $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
        $setting = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/policies/crossTenantAccessPolicy/default"
    }
    process {
        foreach ($prop in '@odata.context','id','@odata.etag','policyTenantId','tenantGroup','supportedClouds','migrationStatus','version','lastModifiedDateTime','applyDefaultsToDomainBasedOrganizations') { $setting.PSObject.Properties.Remove($prop) | Out-Null }
        $export = [ordered]@{
            displayName = 'CrossTenantAccessDefaultSettings'
            inboundTrust = $setting.inboundTrust
            automaticUserConsentSettings = $setting.automaticUserConsentSettings
            b2bCollaborationOutbound = $setting.b2bCollaborationOutbound
            b2bCollaborationInbound = $setting.b2bCollaborationInbound
            b2bDirectConnectOutbound = $setting.b2bDirectConnectOutbound
            b2bDirectConnectInbound = $setting.b2bDirectConnectInbound
            invitationRedemptionIdentityProviderConfiguration = $setting.invitationRedemptionIdentityProviderConfiguration
            tenantRestrictions = $setting.tenantRestrictions
            present = $true
        }
        if ($setting.PSObject.Properties['isServiceDefault']) { $export.isServiceDefault = $setting.isServiceDefault }
    }
    end {
        if (-not $OutPutPath) { return $export }
        $folderPath = Join-Path -Path $OutPutPath -ChildPath "crossTenantAccess/$resourceName"
        if (-not (Test-Path -LiteralPath $folderPath)) { $parent = Split-Path $folderPath; if (-not (Test-Path -LiteralPath $parent)) { New-Item -Path (Split-Path $parent) -Name (Split-Path $parent -Leaf) -ItemType Directory -Force | Out-Null }; New-Item -Path (Split-Path $folderPath) -Name (Split-Path $folderPath -Leaf) -ItemType Directory -Force | Out-Null }
        $export | ConvertTo-Json -Depth 15 | Out-File -FilePath "$folderPath/$resourceName.json" -Encoding utf8 -Force
    }
}