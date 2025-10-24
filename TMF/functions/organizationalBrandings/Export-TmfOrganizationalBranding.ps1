<#
.SYNOPSIS
Exports organizational branding (default + localizations) into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves default branding and localization variants for the tenant and serializes selected properties. Returns objects unless -OutPath is supplied.
.PARAMETER SpecificResources
Optional list of localization IDs or display names (comma separated accepted). Include 'default' or '0' for default branding. When omitted all are exported.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval.
.PARAMETER Append
Add content to an existing file
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfOrganizationalBranding -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfOrganizationalBranding -SpecificResources default,en-US
#>
function Export-TmfOrganizationalBranding {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $Append,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'organizationalBrandings'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $exports = @()
        $apiBase = if ($ForceBeta) {
            $script:graphBaseUrlbeta 
        } else {
            $script:graphBaseUrl1 
        }
        $defaultBranding = Invoke-MgGraphRequest -Method GET -Uri "$apiBase/organization/$($tenant.id)/branding"
        $localizations = (Invoke-MgGraphRequest -Method GET -Uri "$apiBase/organization/$($tenant.id)/branding/localizations").value
        $properties = 'backgroundColor', 'customAccountResetCredentialsUrl', 'customCannotAccessYourAccountText', 'customCannotAccessYourAccountUrl', 'customForgotMyPasswordText', 'customPrivacyAndCookiesText', 'customPrivacyAndCookiesUrl', 'customResetItNowText', 'customTermsOfUseText', 'customTermsOfUseUrl', 'headerBackgroundColor', 'signInPageText', 'usernameHintText'
        function Convert-Branding {
            param([object]$branding, [string]$name) $o = [ordered]@{displayName = $name; present = $true }; foreach ($p in $properties) {
                if ($branding.$p) {
                    $o[$p] = $branding.$p 
                } 
            }; return $o 
        }
    }
    process {
        if ($SpecificResources) {
            $names = @(); foreach ($entry in $SpecificResources) {
                $names += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $names = $names | Select-Object -Unique
            foreach ($name in $names) {
                if ($name -in @('default', '0')) {
                    $exports += Convert-Branding $defaultBranding 'default' 
                } else {
                    $match = $localizations | Where-Object { $_.id -eq $name -or $_.displayName -eq $name }; if ($match) {
                        foreach ($m in $match) {
                            $exports += Convert-Branding $m $m.id 
                        } 
                    } else {
                        Write-PSFMessage -Level Warning -FunctionName 'Export-TmfOrganizationalBranding' -String 'TMF.Export.NotFound' -StringValues $name, $resourceName, $tenant.displayName 
                    } 
                } 
            }
        } else {
            $exports += Convert-Branding $defaultBranding 'default'; foreach ($loc in $localizations) {
                if ($loc.id -ne "0") {
                    $exports += Convert-Branding $loc $loc.id 
                }                
            } 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfOrganizationalBranding' -Message "Exporting $($exports.Count) branding record(s)"
        if ($OutPath) {
            if ($exports) {
                if ($Append) {
                    Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $exports -Append
                }
                else {
                    Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $exports
                }
            }
        } else {
            return $exports
        }
    }
}
