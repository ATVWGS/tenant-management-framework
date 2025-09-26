<#
.SYNOPSIS
Exports cross-tenant access partner settings into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves partner settings from Microsoft Graph (v1.0 by default; beta when -ForceBeta) resolving each partner's primary domain. Returns objects unless -OutPath is supplied, in which case JSON is written to crossTenantAccess/crossTenantAccessPartnerSettings/crossTenantAccessPartnerSettings.json. (Legacy alias: -OutPutPath)
.PARAMETER SpecificResources
Optional list of partner tenant IDs (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write the export. When omitted, objects are returned instead of writing files. (Legacy alias: -OutPutPath)
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCrossTenantAccessPartnerSetting -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfCrossTenantAccessPartnerSetting -SpecificResources "1111-2222-3333" | ConvertTo-Json -Depth 15
#>
function Export-TmfCrossTenantAccessPartnerSetting {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessPartnerSettings'
        $graphBase = if ($ForceBeta) {
            $script:graphBaseUrl 
        } else {
            $script:graphBaseUrl1 
        }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $exports = @()
        $partners = (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/policies/crossTenantAccessPolicy/partners").value
        $tenantPrimaryDomainCache = @{}
        $resolvePartnerPrimaryDomain = { param($tenantId) if (-not $tenantId) {
                return $null 
            }; if ($tenantPrimaryDomainCache.ContainsKey($tenantId)) {
                return $tenantPrimaryDomainCache[$tenantId] 
            } ; $primaryDomain = $null; $displayNameFallback = $null; try {
                $uri = "$graphBase/tenantRelationships/findTenantInformationByTenantId(tenantId='$tenantId')"; $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop; $data = if ($resp.PSObject.Properties['value'] -and ($resp.value -isnot [string])) {
                    $resp.value 
                } else {
                    $resp 
                }; if ($data) {
                    if ($data.PSObject.Properties['defaultDomainName']) {
                        $primaryDomain = $data.defaultDomainName 
                    }; if ($data.PSObject.Properties['displayName']) {
                        $displayNameFallback = $data.displayName 
                    } 
                } 
            } catch {
                Write-PSFMessage -Level Verbose -Message "Primary domain lookup failed for '$tenantId': $($_.Exception.Message)" -FunctionName 'Export-TmfCrossTenantAccessPartnerSetting' 
            } ; if (-not $primaryDomain) {
                $primaryDomain = $displayNameFallback 
            }; if (-not $primaryDomain) {
                $primaryDomain = $tenantId 
            }; if (-not $primaryDomain -or $primaryDomain -eq $tenantId) {
                Write-PSFMessage -Level Warning -Message "Could not retrieve defaultDomainName for partner tenant '$tenantId'. Using fallback '$primaryDomain'." -FunctionName 'Export-TmfCrossTenantAccessPartnerSetting' 
            } ; $tenantPrimaryDomainCache[$tenantId] = $primaryDomain; return $primaryDomain }
    }
    process {
        if ($SpecificResources) {
            $ids = @(); foreach ($entry in $SpecificResources) {
                $ids += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $ids = $ids | Select-Object -Unique
            foreach ($id in $ids) {
                $match = $partners | Where-Object { $_.tenantId -eq $id }
                if ($match) {
                    foreach ($m in $match) {
                        foreach ($prop in '@odata.context', 'id', '@odata.etag', 'policyTenantId', 'tenantGroup', 'supportedClouds', 'migrationStatus', 'version', 'lastModifiedDateTime', 'applyDefaultsToDomainBasedOrganizations') {
                            $m.PSObject.Properties.Remove($prop) | Out-Null 
                        }
                        $partnerDisplayName = & $resolvePartnerPrimaryDomain $m.tenantId
                        if ($partnerDisplayName -eq $m.tenantId -and $m.PSObject.Properties['displayName'] -and $m.displayName) {
                            $partnerDisplayName = $m.displayName 
                        }
                        $obj = [ordered]@{ displayName = $partnerDisplayName; tenantId = $m.tenantId; present = $true; inboundTrust = $m.inboundTrust; b2bCollaborationOutbound = $m.b2bCollaborationOutbound; b2bCollaborationInbound = $m.b2bCollaborationInbound; b2bDirectConnectOutbound = $m.b2bDirectConnectOutbound; b2bDirectConnectInbound = $m.b2bDirectConnectInbound; tenantRestrictions = $m.tenantRestrictions; invitationRedemptionIdentityProviderConfiguration = $m.invitationRedemptionIdentityProviderConfiguration; automaticUserConsentSettings = $m.automaticUserConsentSettings }
                        if ($m.PSObject.Properties['isInMultiTenantOrganization']) {
                            $obj.isInMultiTenantOrganization = $m.isInMultiTenantOrganization 
                        }
                        if ($m.PSObject.Properties['isServiceProvider']) {
                            $obj.isServiceProvider = $m.isServiceProvider 
                        }
                        $exports += $obj
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfCrossTenantAccessPartnerSetting' -String 'TMF.Export.NotFound' -StringValues $id, $resourceName, $tenant.displayName 
                }
            }
        } else {
            foreach ($p in $partners) {
                foreach ($prop in '@odata.context', 'id', '@odata.etag', 'policyTenantId', 'tenantGroup', 'supportedClouds', 'migrationStatus', 'version', 'lastModifiedDateTime', 'applyDefaultsToDomainBasedOrganizations') {
                    $p.PSObject.Properties.Remove($prop) | Out-Null 
                }
                $partnerDisplayName = & $resolvePartnerPrimaryDomain $p.tenantId
                if ($partnerDisplayName -eq $p.tenantId -and $p.PSObject.Properties['displayName'] -and $p.displayName) {
                    $partnerDisplayName = $p.displayName 
                }
                $obj = [ordered]@{ displayName = $partnerDisplayName; tenantId = $p.tenantId; present = $true; inboundTrust = $p.inboundTrust; b2bCollaborationOutbound = $p.b2bCollaborationOutbound; b2bCollaborationInbound = $p.b2bCollaborationInbound; b2bDirectConnectOutbound = $p.b2bDirectConnectOutbound; b2bDirectConnectInbound = $p.b2bDirectConnectInbound; tenantRestrictions = $p.tenantRestrictions; invitationRedemptionIdentityProviderConfiguration = $p.invitationRedemptionIdentityProviderConfiguration; automaticUserConsentSettings = $p.automaticUserConsentSettings }
                if ($p.PSObject.Properties['isInMultiTenantOrganization']) {
                    $obj.isInMultiTenantOrganization = $p.isInMultiTenantOrganization 
                }
                if ($p.PSObject.Properties['isServiceProvider']) {
                    $obj.isServiceProvider = $p.isServiceProvider 
                }
                $exports += $obj
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCrossTenantAccessPartnerSetting' -Message "Exporting $($exports.Count) partner setting(s). ForceBeta=$ForceBeta"
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'crossTenantAccess' -ResourceName $resourceName -Data $exports
        } else {
            return $exports
        }
    }
}
