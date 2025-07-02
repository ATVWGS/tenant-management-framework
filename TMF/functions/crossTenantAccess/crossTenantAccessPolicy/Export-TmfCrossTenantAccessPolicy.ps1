function Export-TmfCrossTenantAccessPolicy {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'crossTenantAccessPolicy'
        $export = @()
        $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/policies/crossTenantAccessPolicy"
    }
    process {
        $policy.PSObject.Properties.Remove('@odata.context') | Out-Null
        $obj = [ordered]@{
            displayName         = 'CrossTenantAccessPolicy'
            allowedCloudEndpoints = $policy.allowedCloudEndpoints
        }
        $export += $obj
    }
    end {
        $folderPath = Join-Path -Path $OutPutPath -ChildPath "crossTenantAccess/$resourceName"
        if (-not (Test-Path $folderPath)) {
            New-Item -Path (Split-Path $folderPath) -Name (Split-Path $folderPath -Leaf) -ItemType Directory -Force | Out-Null
        }
        $export | ConvertTo-Json -Depth 10 | Out-File -FilePath "$folderPath/$resourceName.json" -Encoding utf8 -Force
    }
}