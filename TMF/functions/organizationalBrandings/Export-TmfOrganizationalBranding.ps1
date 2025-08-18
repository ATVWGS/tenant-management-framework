<#
.SYNOPSIS
Exports organizational branding (default + localizations) into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves default branding and localization variants for the tenant and serializes selected properties. Returns objects unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional list of localization IDs or display names (comma separated accepted). Include 'default' or '0' for default branding. When omitted all are exported.
.PARAMETER OutPutPath
Root folder to write export; when omitted objects are returned.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfOrganizationalBranding -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfOrganizationalBranding -SpecificResources default,en-US
#>
function Export-TmfOrganizationalBranding {
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'organizationalBrandings'
        $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/organization?`$select=displayname,id")).value
        $exports = @()
        $defaultBranding = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/organization/$($tenant.id)/branding"
        $localizations = (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/organization/$($tenant.id)/branding/localizations").value
        $properties = 'backgroundColor','customAccountResetCredentialsUrl','customCannotAccessYourAccountText','customCannotAccessYourAccountUrl','customForgotMyPasswordText','customPrivacyAndCookiesText','customPrivacyAndCookiesUrl','customResetItNowText','customTermsOfUseText','customTermsOfUseUrl','headerBackgroundColor','signInPageText','usernameHintText'
        function Convert-Branding { param([object]$branding,[string]$name) $o=[ordered]@{displayName=$name;present=$true}; foreach ($p in $properties) { if ($branding.PSObject.Properties[$p]) { $o[$p]=$branding.$p } }; return $o }
    }
    process {
        if ($SpecificResources) {
            $names=@(); foreach ($entry in $SpecificResources) { $names += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }; $names = $names | Select-Object -Unique
            foreach ($name in $names) { if ($name -in @('default','0')) { $exports += Convert-Branding $defaultBranding 'default' } else { $match = $localizations | Where-Object { $_.id -eq $name -or $_.displayName -eq $name }; if ($match) { foreach ($m in $match) { $exports += Convert-Branding $m $m.id } } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfOrganizationalBranding' -String 'TMF.Export.NotFound' -StringValues $name,$resourceName,$tenant.displayName } } }
        } else { $exports += Convert-Branding $defaultBranding 'default'; foreach ($loc in $localizations) { $exports += Convert-Branding $loc $loc.id } }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfOrganizationalBranding' -Message "Exporting $($exports.Count) branding record(s)"
        if (-not $OutPutPath) { return $exports }
        $targetDir = Join-Path -Path $OutPutPath -ChildPath $resourceName
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -Path $OutPutPath -Name $resourceName -ItemType Directory -Force | Out-Null }
        $exports | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir "$resourceName.json") -Encoding utf8 -Force
    }
}