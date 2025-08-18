<#
.SYNOPSIS
Exports the tenant authentication methods policy into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves the singleton authenticationMethodsPolicy (v1.0 by default; beta when -ForceBeta for fallbacks) and its authenticationMethodConfigurations, converting to the TMF shape. Returns object unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional filter by display name (singleton semantics; rarely needed).
.PARAMETER OutPutPath
Root folder to write the export. When omitted, object is returned instead of writing files.
.PARAMETER ForceBeta
Use beta Graph endpoint for initial retrieval (fallback to beta already occurs when v1.0 lacks detail).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAuthenticationMethodsPolicy -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfAuthenticationMethodsPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfAuthenticationMethodsPolicy {
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/authenticationMethodsPolicies'
        $fileName = 'authenticationMethodsPolicies.json'

        function Convert-AuthenticationMethodsPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy
            )

            $obj = [ordered]@{ present = $true }

            if ($policy.PSObject.Members.Match('displayName') -and $null -ne $policy.displayName -and $policy.displayName -ne '') {
                $obj.displayName = $policy.displayName
            }

            # registrationEnforcement (keep as-is if present)
            if ($policy.PSObject.Members.Match('registrationEnforcement') -and $null -ne $policy.registrationEnforcement) {
                $obj.registrationEnforcement = $policy.registrationEnforcement
            }

            # authenticationMethodConfigurations
            if ($policy.PSObject.Members.Match('authenticationMethodConfigurations') -and $null -ne $policy.authenticationMethodConfigurations) {
                $converted = @()
                foreach ($cfg in $policy.authenticationMethodConfigurations) {
                    if ($null -eq $cfg) { continue }
                    $entry = [ordered]@{}
                    # Always keep id
                    if ($cfg.PSObject.Members.Match('id') -and $null -ne $cfg.id) { $entry.id = $cfg.id }

                    # Known common properties across methods
                    foreach ($p in @('state','isSelfServiceRegistrationAllowed','isAttestationEnforced','defaultLifetimeInMinutes','defaultLength','minimumLifetimeInMinutes','maximumLifetimeInMinutes','isUsableOnce','allowExternalIdToUseEmailOtp','certificateUserBindings','authenticationModeConfiguration')) {
                        if ($cfg.PSObject.Members.Match($p) -and $null -ne $cfg.$p) { $entry[$p] = $cfg.$p }
                    }

                    # Copy any remaining note properties (excluding @odata.type and id) not already set
                    $noteProps = ($cfg | Get-Member -MemberType NoteProperty).Name
                    foreach ($m in $noteProps) {
                        if ($m -in '@odata.type','id') { continue }
                        if (-not $entry.Contains($m)) { $entry[$m] = $cfg.$m }
                    }

                    if ($entry.Count -gt 0) { $converted += [pscustomobject]$entry }
                }
                if ($converted.Count -gt 0) { $obj.authenticationMethodConfigurations = $converted }
            }

            return [pscustomobject]$obj
        }
    }
    process {
        # Fetch singleton from v1.0 with expanded configurations
    $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
    try { $policy = Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/policies/authenticationMethodsPolicy?`$expand=authenticationMethodConfigurations") } catch { throw $_ }

        if (-not $policy) { return @() }

        # Build from IDs on the policy response to fetch full properties for each configuration
        if ($policy.PSObject.Members.Match('authenticationMethodConfigurations') -and $null -ne $policy.authenticationMethodConfigurations) {
            $hasProps = $false
            foreach ($itm in $policy.authenticationMethodConfigurations) {
                if ($null -eq $itm) { continue }
                $names = (($itm | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -ne 'id' -and $_ -ne '@odata.type' })
                if ($names.Count -gt 0) { $hasProps = $true; break }
            }

            if (-not $hasProps) {
                $ids = @()
                foreach ($item in $policy.authenticationMethodConfigurations) {
                    if ($null -eq $item) { continue }
                    if ($item -is [string]) { $ids += $item; continue }
                    if ($item.PSObject.Members.Match('id') -and $null -ne $item.id -and $item.id -ne '') { $ids += $item.id }
                }
                $ids = $ids | Where-Object { $_ } | Select-Object -Unique

                if ($ids.Count -gt 0) {
                    $full = @()
                    foreach ($id in $ids) {
                        try {
                            $cfg = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/$id")
                            if ($cfg) { $full += $cfg }
                        }
                        catch {
                            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationMethodsPolicy' -Message "Skipping configuration $id due to error: $_"
                        }
                    }

                    # If v1.0 per-id fetch still returns id-only, try beta per-id as a last resort (when allowed)
                    $needsBeta = $false
                    if ($full.Count -gt 0) {
                        $allIdOnly = $true
                        foreach ($cfg in $full) {
                            if ($null -eq $cfg) { continue }
                            $pn = (($cfg | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -ne 'id' -and $_ -ne '@odata.type' })
                            if ($pn.Count -gt 0) { $allIdOnly = $false; break }
                        }
                        if ($allIdOnly) { $needsBeta = $true }
                    } else { $needsBeta = $true }

                    if ($needsBeta) {
                        $betaFull = @()
                        foreach ($id in $ids) {
                            try {
                                $cfgB = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/$id")
                                if ($cfgB) { $betaFull += $cfgB }
                            }
                            catch {
                                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationMethodsPolicy' -Message "Skipping configuration $id (beta) due to error: $_"
                            }
                        }
                        if ($betaFull.Count -gt 0) { $full = $betaFull }
                    }

                    if ($full.Count -gt 0) { $policy.authenticationMethodConfigurations = $full }
                }
            }
        }

        $exportObject = Convert-AuthenticationMethodsPolicy -policy $policy

        # Optional filtering by display name (singleton semantics)
        if ($SpecificResources -and ($SpecificResources -notcontains $exportObject.displayName) -and ($SpecificResources -notcontains '*')) {
            # Nothing to export if filter doesn't match
            if (-not $OutPutPath) { return @() }
            else { return }
        }

        if (-not $OutPutPath) {
            return @($exportObject)
        }
    }
    end {
    Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationMethodsPolicy' -Message "Exporting authentication methods policy. ForceBeta=$ForceBeta"
    if (-not $OutPutPath) { return @($exportObject) }
    $targetDir = Join-Path -Path $OutPutPath -ChildPath $resourceFolder
    if (-not (Test-Path -LiteralPath $targetDir)) { if (-not (Test-Path -LiteralPath (Join-Path $OutPutPath 'policies'))) { New-Item -ItemType Directory -Path (Join-Path $OutPutPath 'policies') -Force | Out-Null }; New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    @($exportObject) | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir $fileName) -Encoding utf8 -Force
    }
}
