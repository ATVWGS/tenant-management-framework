function Export-TmfCrossTenantAccessPartnerSetting {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessPartnerSettings'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        $exports = @()
        $partners = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/policies/crossTenantAccessPolicy/partners").value
    }
    process {
        if ($SpecificResources) {
            $ids = @()
            foreach ($entry in $SpecificResources) {
                $ids += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            $ids = $ids | Select-Object -Unique
            foreach ($id in $ids) {
                $match = $partners | Where-Object { $_.tenantId -eq $id }
                if ($match) {
                    foreach ($m in $match) {
                        foreach ($prop in '@odata.context','id','@odata.etag','policyTenantId','tenantGroup','supportedClouds','migrationStatus','version','lastModifiedDateTime','applyDefaultsToDomainBasedOrganizations') {
                            $m.PSObject.Properties.Remove($prop) | Out-Null
                        }
                        $obj = [ordered]@{
                            # displayName = $m.displayName
                            tenantId = $m.tenantId
                            present = $true
                            inboundTrust = $m.inboundTrust
                            b2bCollaborationOutbound = $m.b2bCollaborationOutbound
                            b2bCollaborationInbound = $m.b2bCollaborationInbound
                            b2bDirectConnectOutbound = $m.b2bDirectConnectOutbound
                            b2bDirectConnectInbound = $m.b2bDirectConnectInbound
                            tenantRestrictions = $m.tenantRestrictions
                            invitationRedemptionIdentityProviderConfiguration = $m.invitationRedemptionIdentityProviderConfiguration
                            automaticUserConsentSettings = $m.automaticUserConsentSettings
                        }
                        if ($m.PSObject.Properties['isInMultiTenantOrganization']) { $obj.isInMultiTenantOrganization = $m.isInMultiTenantOrganization }
                        if ($m.PSObject.Properties['isServiceProvider']) { $obj.isServiceProvider = $m.isServiceProvider }
                        $exports += $obj
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCrossTenantAccessPartnerSetting' -String 'TMF.Export.NotFound' -StringValues $id,$resourceName,$tenant.displayName
                }
            }
        } else {
            foreach ($p in $partners) {
                foreach ($prop in '@odata.context','id','@odata.etag','policyTenantId','tenantGroup','supportedClouds','migrationStatus','version','lastModifiedDateTime','applyDefaultsToDomainBasedOrganizations') {
                    $p.PSObject.Properties.Remove($prop) | Out-Null
                }
                $obj = [ordered]@{
                    displayName = $p.displayName
                    tenantId = $p.tenantId
                    present = $true
                    inboundTrust = $p.inboundTrust
                    b2bCollaborationOutbound = $p.b2bCollaborationOutbound
                    b2bCollaborationInbound = $p.b2bCollaborationInbound
                    b2bDirectConnectOutbound = $p.b2bDirectConnectOutbound
                    b2bDirectConnectInbound = $p.b2bDirectConnectInbound
                    tenantRestrictions = $p.tenantRestrictions
                    invitationRedemptionIdentityProviderConfiguration = $p.invitationRedemptionIdentityProviderConfiguration
                    automaticUserConsentSettings = $p.automaticUserConsentSettings
                }
                if ($p.PSObject.Properties['isInMultiTenantOrganization']) { $obj.isInMultiTenantOrganization = $p.isInMultiTenantOrganization }
                if ($p.PSObject.Properties['isServiceProvider']) { $obj.isServiceProvider = $p.isServiceProvider }
                $exports += $obj
            }
        }
    }
    end {
        $folderPath = Join-Path -Path $OutPutPath -ChildPath "crossTenantAccess/$resourceName"
        if (-not (Test-Path $folderPath)) {
            New-Item -Path (Split-Path $folderPath) -Name (Split-Path $folderPath -Leaf) -ItemType Directory -Force | Out-Null
        }
        $exports | ConvertTo-Json -Depth 10 | Out-File -FilePath "$folderPath/$resourceName.json" -Encoding utf8 -Force
    }
}