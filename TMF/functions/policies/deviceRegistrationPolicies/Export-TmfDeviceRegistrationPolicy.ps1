<#
.SYNOPSIS
Exports the device registration policy into TMF configuration object or JSON.
.DESCRIPTION
Retrieves the deviceRegistrationPolicy singleton (v1.0 by default; beta when -ForceBeta) and converts it to the TMF shape. Returns object unless -OutPath is supplied.
.PARAMETER OutPath
Root folder to write the export. When omitted, object is returned instead of writing files. Legacy alias -OutPutPath is deprecated.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfDeviceRegistrationPolicy -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfDeviceRegistrationPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfDeviceRegistrationPolicy {
    [CmdletBinding()] Param(
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/deviceRegistrationPolicy'
        $fileName = 'deviceRegistrationPolicy.json'

        function Convert-DeviceRegistrationPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy
            )

            $obj = [ordered]@{ present = $true; displayName = "deviceRegistrationPolicy" }

            foreach ($p in @('multiFactorAuthConfiguration','userDeviceQuota','azureADRegistration','localAdminPassword')) {
                if ($p -in $policy.keys -and $null -ne $policy.$p ) { $obj[$p] = $policy.$p }
            }
            # add azureADJoin
            if ($policy.azureADJoin.allowedToJoin."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership" -or $policy.azureADJoin.localAdmins.registeringUsers."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {
                $tmpObj = @{}
                $tmpObj["isAdminConfigurable"] = $policy.azureADJoin.isAdminConfigurable
                if ($policy.azureADJoin.allowedToJoin."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {
                    $tmpObj["allowedToJoin"] = @{}
                    $tmpObj["allowedToJoin"]["@odata.type"] = "#microsoft.graph.enumeratedDeviceRegistrationMembership"
                    if ($policy.azureADJoin.allowedToJoin.users) {
                        $tmpObj["allowedToJoin"]["users"] = @()
                        foreach ($user in $policy.azureADJoin.allowedToJoin.users) {$tmpObj["allowedToJoin"]["users"] += Resolve-User -InputReference $user -UserPrincipalName}
                    }
                    else {
                        $tmpObj["allowedToJoin"]["users"] = @()
                    }
                    if ($policy.azureADJoin.allowedToJoin.groups) {
                        $tmpObj["allowedToJoin"]["groups"] = @()
                        foreach ($group in $policy.azureADJoin.allowedToJoin.groups) {$tmpObj["allowedToJoin"]["groups"] += Resolve-Group -InputReference $group -DisplayName}
                    }
                    else {
                        $tmpObj["allowedToJoin"]["groups"] = @()
                    }
                }
                else {
                    $tmpObj["allowedToJoin"] = $policy.azureADJoin.allowedToJoin
                }
                if ($policy.azureADJoin.localAdmins.registeringUsers."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {
                    $tmpObj["localAdmins"] = @{}
                    $tmpObj["localAdmins"]["enableGlobalAdmins"] = $policy.azureADJoin.localAdmins.enableGlobalAdmins
                    $tmpObj["localAdmins"]["registeringUsers"] = @{} 
                    $tmpObj["localAdmins"]["registeringUsers"]["@odata.type"] = "#microsoft.graph.enumeratedDeviceRegistrationMembership"
                    if ($policy.azureADJoin.localAdmins.registeringUsers.users) {
                        $tmpObj["localAdmins"]["registeringUsers"]["users"] = @()
                        foreach ($user in $policy.azureADJoin.localAdmins.registeringUsers.users) {$tmpObj["localAdmins"]["registeringUsers"]["users"] += Resolve-User -InputReference $user -UserPrincipalName}
                    }
                    else {
                        $tmpObj["localAdmins"]["registeringUsers"]["users"] = @()
                    }
                    if ($policy.azureADJoin.localAdmins.registeringUsers.groups) {
                        $tmpObj["localAdmins"]["registeringUsers"]["groups"] = @()
                        foreach ($group in $policy.azureADJoin.localAdmins.registeringUsers.groups) {$tmpObj["localAdmins"]["registeringUsers"]["groups"] += Resolve-Group -InputReference $group -DisplayName}
                    }
                    else {
                        $tmpObj["localAdmins"]["registeringUsers"]["groups"] = @()
                    }
                }
                else {
                    $tmpObj["localAdmins"] = $policy.azureADJoin.localAdmins
                }

                $obj["azureADJoin"] = $tmpObj
            }
            else {
                $obj["azureADJoin"] = $policy.azureADJoin
            }
            

            return [pscustomobject]$obj
        }
    }
    process {
        $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
        try { $policy = Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/policies/deviceRegistrationPolicy") } catch { throw $_ }

            if (-not $policy) { return @() }

            $exportObject = Convert-DeviceRegistrationPolicy -policy $policy
            if (-not $OutPath) { return @($exportObject) }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfDeviceRegistrationPolicy' -Message "Exporting device registration request policy. ForceBeta=$ForceBeta"
        if (-not $OutPath) { return @($exportObject) }
        $targetDir = Join-Path -Path $OutPath -ChildPath $resourceFolder
        if (-not (Test-Path -LiteralPath $targetDir)) { if (-not (Test-Path -LiteralPath (Join-Path $OutPath 'policies'))) { New-Item -ItemType Directory -Path (Join-Path $OutPath 'policies') -Force | Out-Null }; New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        @($exportObject) | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir $fileName) -Encoding utf8 -Force
    }
}
