function Export-TmfOrganizationalBranding {
    [CmdletBinding()]
    Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'organizationalBrandings'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/organization?`$select=displayname,id")).value
        $exports = @()
        $defaultBranding = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl1/organization/$($tenant.id)/branding"
        $localizations = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl1/organization/$($tenant.id)/branding/localizations").value
        $properties = @(
            'backgroundColor','customAccountResetCredentialsUrl','customCannotAccessYourAccountText',
            'customCannotAccessYourAccountUrl','customForgotMyPasswordText','customPrivacyAndCookiesText',
            'customPrivacyAndCookiesUrl','customResetItNowText','customTermsOfUseText','customTermsOfUseUrl',
            'headerBackgroundColor','signInPageText','usernameHintText'
        )
        function Convert-Branding {
            param([object]$branding,[string]$name)
            $obj = [ordered]@{
                displayName = $name
                present = $true
            }
            foreach ($prop in $properties) {
                if ($branding.PSObject.Properties[$prop]) { $obj[$prop] = $branding.$prop }
            }
            return $obj
        }
    }
    process {
        if ($SpecificResources) {
            $names = @()
            foreach ($entry in $SpecificResources) { $names += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
            $names = $names | Select-Object -Unique
            foreach ($name in $names) {
                if ($name -eq 'default' -or $name -eq '0') {
                    $exports += Convert-Branding $defaultBranding 'default'
                } else {
                    $match = $localizations | Where-Object { $_.id -eq $name -or $_.displayName -eq $name }
                    if ($match) { foreach ($m in $match) { $exports += Convert-Branding $m $m.id } }
                    else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfOrganizationalBranding' -String 'TMF.Export.NotFound' -StringValues $name,$resourceName,$tenant.displayName }
                }
            }
        } else {
            $exports += Convert-Branding $defaultBranding 'default'
            foreach ($loc in $localizations) { $exports += Convert-Branding $loc $loc.id }
        }
    }
    end {
        if (-not (Test-Path "$OutPutPath/$($resourceName)")) { New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force | Out-Null }
        $exports | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutPutPath/$resourceName/$resourceName.json" -Encoding utf8 -Force
    }
}