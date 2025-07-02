function Export-TmfCrossTenantAccessDefaultSetting {
    [CmdletBinding()]
    Param(
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessDefaultSettings'
        $export = @()
        $setting = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/policies/crossTenantAccessPolicy/default"
    }
    process {
        foreach ($prop in '@odata.context','id','@odata.etag','policyTenantId','tenantGroup','supportedClouds','migrationStatus','version','lastModifiedDateTime','applyDefaultsToDomainBasedOrganizations') {
            $setting.PSObject.Properties.Remove($prop) | Out-Null
        }
        $ordered = [ordered]@{}
        $ordered.displayName = "CrossTenantAccessDefaultSettings"
        $ordered.inboundTrust = $setting.inboundTrust
        $ordered.automaticUserConsentSettings = $setting.automaticUserConsentSettings
        $ordered.b2bCollaborationOutbound = $setting.b2bCollaborationOutbound
        $ordered.b2bCollaborationInbound = $setting.b2bCollaborationInbound
        $ordered.b2bDirectConnectOutbound = $setting.b2bDirectConnectOutbound
        $ordered.b2bDirectConnectInbound = $setting.b2bDirectConnectInbound
        $ordered.invitationRedemptionIdentityProviderConfiguration = $setting.invitationRedemptionIdentityProviderConfiguration
        if ($setting.PSObject.Properties['isServiceDefault']) { $ordered.isServiceDefault = $setting.isServiceDefault }
        $ordered.tenantRestrictions = $setting.tenantRestrictions
        $export += $ordered
    }
    end {
        $folderPath = Join-Path -Path $OutPutPath -ChildPath "crossTenantAccess/$resourceName"
        if (-not (Test-Path $folderPath)) {
            New-Item -Path (Split-Path $folderPath) -Name (Split-Path $folderPath -Leaf) -ItemType Directory -Force | Out-Null
        }
        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath "$folderPath/$resourceName.json" -Encoding utf8 -Force
    }
}