function Export-TmfAuthorizationPolicy {
<#
.SYNOPSIS
Retrieves the singleton authorizationPolicy (v1.0 by default; beta when -ForceBeta or v1.0 unsupported) and converts it to the TMF shape. Returns object unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional filter by display name (wildcards). Singleton; typically omitted.
.PARAMETER OutPutPath
Root folder to write export; when omitted the object is returned.
.PARAMETER ForceBeta
Always use beta endpoint (or fallback when v1.0 fails/insufficient).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAuthorizationPolicy -OutPutPath C:\tmf
.EXAMPLE
Export-TmfAuthorizationPolicy | ConvertTo-Json -Depth 15
#>
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/authorizationPolicies'
        $fileName = 'authorizationPolicies.json'
        $graphV1 = $script:graphBaseUrl1
        $graphBeta = $script:graphBaseUrl
        function Convert-AuthorizationPolicy { param([object]$policy) $o = [ordered]@{ present = $true }; if ($policy.displayName) { $o.displayName = $policy.displayName }; foreach ($p in 'allowInvitesFrom','allowedToSignUpEmailBasedSubscriptions','allowedToUseSSPR','allowEmailVerifiedUsersToJoinOrganization','blockMsolPowerShell','guestUserRole','allowedToCreateApps','allowedToCreateSecurityGroups','allowedToReadOtherUsers','allowedToReadBitlockerKeysForOwnedDevice','permissionGrantPolicyIdsAssignedToDefaultUserRole') { if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p) { $o[$p] = $policy.$p } }; if ($policy.defaultUserRolePermissions) { $durp = $policy.defaultUserRolePermissions; foreach ($prop in $durp.PSObject.Properties) { if ($prop.Name -ne '@odata.type' -and $null -ne $prop.Value) { $o[$prop.Name] = $prop.Value } } }; [pscustomobject]$o }
    }
    process {
        $policy = $null; $usedBeta = $false
        if (-not $ForceBeta) { try { $policy = Invoke-MgGraphRequest -Method GET -Uri "$graphV1/policies/authorizationPolicy" } catch { Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) } }
        if ($ForceBeta -or -not $policy) { try { $policy = Invoke-MgGraphRequest -Method GET -Uri "$graphBeta/policies/authorizationPolicy"; $usedBeta = $true } catch { Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message) } }
        if (-not $policy) { if (-not $OutPutPath) { return @() } else { return } }
        $exportObject = Convert-AuthorizationPolicy $policy
        if ($SpecificResources) { $filters = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ }; if (($filters | Where-Object { $exportObject.displayName -like $_ }).Count -eq 0 -and ($filters -notcontains '*')) { if (-not $OutPutPath) { return @() } else { return } } }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthorizationPolicy' -Message ("Exporting authorization policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta,$usedBeta)
        if (-not $OutPutPath) { return @($exportObject) }
    }
    end {
        if ($OutPutPath) {
            $targetDir = Join-Path -Path $OutPutPath -ChildPath $resourceFolder
            if (-not (Test-Path -LiteralPath (Join-Path $OutPutPath 'policies'))) { New-Item -ItemType Directory -Path (Join-Path $OutPutPath 'policies') -Force | Out-Null }
            if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
            @($exportObject) | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir $fileName) -Encoding utf8 -Force
        }
    }
}
