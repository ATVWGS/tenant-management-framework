<#
.SYNOPSIS
Retrieves the crossTenantAccessPolicy singleton (v1.0 by default; beta with -ForceBeta or fallback) and maps key properties to a TMF object. Returns object unless -OutPath supplied. (Legacy alias: -OutPutPath)
.PARAMETER SpecificResources
Ignored (singleton) but accepted for consistency; wildcard accepted.
.PARAMETER OutPath
Root folder to write export; when omitted the object is returned. (Legacy alias: -OutPutPath)
.PARAMETER Append
Add content to existing file
.PARAMETER ForceBeta
Use beta endpoint (always) or as fallback when v1.0 retrieval fails.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCrossTenantAccessPolicy -OutPath C:\tmf
.EXAMPLE
Export-TmfCrossTenantAccessPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfCrossTenantAccessPolicy {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessPolicy'
        $policy = $null; $usedBeta = $false; $exports = @()
    }
    process {
        if (-not $ForceBeta) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl1/policies/crossTenantAccessPolicy" 
            } catch {
                Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) 
            } 
        }
        if ($ForceBeta -or -not $policy) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrlbeta/policies/crossTenantAccessPolicy"; $usedBeta = $true 
            } catch {
                Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message) 
            } 
        }
        if ($policy) {
            $policy.PSObject.Properties.Remove('@odata.context') | Out-Null
            $obj = [ordered]@{ present = $true; displayName = 'CrossTenantAccessPolicy' }
            if ($policy.allowedCloudEndpoints) {
                $obj.allowedCloudEndpoints = $policy.allowedCloudEndpoints 
            }
            $exports = @([pscustomobject]$obj)
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCrossTenantAccessPolicy' -Message ("Exporting cross-tenant access policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta, $usedBeta)
        }
    }
    end {
        if ($OutPath) {
            if ($exports.Count -gt 0) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'crossTenantAccess' -ResourceName $resourceName -Data $exports -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ParentPath 'crossTenantAccess' -ResourceName $resourceName -Data $exports
                }                
            }
        } else {
            return $exports
        }
    }
}
