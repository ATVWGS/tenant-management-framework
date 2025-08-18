<#
.SYNOPSIS
Retrieves the crossTenantAccessPolicy singleton (v1.0 by default; beta with -ForceBeta or fallback) and maps key properties to a TMF object. Returns object unless -OutPutPath supplied.
.PARAMETER SpecificResources
Ignored (singleton) but accepted for consistency; wildcard accepted.
.PARAMETER OutPutPath
Root folder to write export; when omitted the object is returned.
.PARAMETER ForceBeta
Use beta endpoint (always) or as fallback when v1.0 retrieval fails.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfCrossTenantAccessPolicy -OutPutPath C:\tmf
.EXAMPLE
Export-TmfCrossTenantAccessPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfCrossTenantAccessPolicy {
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessPolicy'
        $graphV1 = $script:graphBaseUrl1
        $graphBeta = $script:graphBaseUrl
    }
    process {
        $policy = $null; $usedBeta = $false
        if (-not $ForceBeta) { try { $policy = Invoke-MgGraphRequest -Method GET -Uri "$graphV1/policies/crossTenantAccessPolicy" } catch { Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) } }
        if ($ForceBeta -or -not $policy) { try { $policy = Invoke-MgGraphRequest -Method GET -Uri "$graphBeta/policies/crossTenantAccessPolicy"; $usedBeta = $true } catch { Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message) } }
        if (-not $policy) { if (-not $OutPutPath) { return @() } else { return } }
        $policy.PSObject.Properties.Remove('@odata.context') | Out-Null
        $obj = [ordered]@{ present=$true; displayName='CrossTenantAccessPolicy' }
        if ($policy.allowedCloudEndpoints) { $obj.allowedCloudEndpoints = $policy.allowedCloudEndpoints }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfCrossTenantAccessPolicy' -Message ("Exporting cross-tenant access policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta,$usedBeta)
        if (-not $OutPutPath) { return @([pscustomobject]$obj) }
        $export = @([pscustomobject]$obj)
        $folderPath = Join-Path -Path $OutPutPath -ChildPath "crossTenantAccess/$resourceName"
        if (-not (Test-Path $folderPath)) { New-Item -Path (Split-Path $folderPath) -Name (Split-Path $folderPath -Leaf) -ItemType Directory -Force | Out-Null }
        $export | ConvertTo-Json -Depth 15 | Out-File -FilePath "$folderPath/$resourceName.json" -Encoding utf8 -Force
    }
    end {}
}