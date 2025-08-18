<#
.SYNOPSIS
Exports the tenant default app management policy into TMF configuration object or JSON.
.DESCRIPTION
Retrieves the defaultAppManagementPolicy singleton (v1.0 by default; beta when -ForceBeta) and converts it to the TMF shape. Returns object unless -OutPutPath is supplied.
.PARAMETER OutPutPath
Root folder to write the export. When omitted, object is returned instead of writing files.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfTenantAppManagementPolicy -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfTenantAppManagementPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfTenantAppManagementPolicy {
    [CmdletBinding()] Param(
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/tenantAppManagementPolicy'
        $fileName = 'tenantAppManagementPolicy.json'

        function Convert-TenantAppManagementPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy
            )

            $obj = [ordered]@{ present = $true }

            foreach ($p in @('displayName','description','isEnabled')) {
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p -and $policy.$p -ne '') { $obj[$p] = $policy.$p }
            }

            foreach ($p in @('applicationRestrictions','servicePrincipalRestrictions')) {
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p) { $obj[$p] = $policy.$p }
            }

            return [pscustomobject]$obj
        }
    }
    process {
    $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
    try { $policy = Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/policies/defaultAppManagementPolicy") } catch { throw $_ }

        if (-not $policy) { return @() }

        $exportObject = Convert-TenantAppManagementPolicy -policy $policy
        if (-not $OutPutPath) { return @($exportObject) }
    }
    end {
    Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfTenantAppManagementPolicy' -Message "Exporting tenant app management policy. ForceBeta=$ForceBeta"
    if (-not $OutPutPath) { return @($exportObject) }
    $targetDir = Join-Path -Path $OutPutPath -ChildPath $resourceFolder
    if (-not (Test-Path -LiteralPath $targetDir)) { if (-not (Test-Path -LiteralPath (Join-Path $OutPutPath 'policies'))) { New-Item -ItemType Directory -Path (Join-Path $OutPutPath 'policies') -Force | Out-Null }; New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    @($exportObject) | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir $fileName) -Encoding utf8 -Force
    }
}
