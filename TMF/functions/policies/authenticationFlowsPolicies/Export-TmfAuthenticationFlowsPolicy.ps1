function Export-TmfAuthenticationFlowsPolicy {
<#
.SYNOPSIS
Retrieves the singleton authenticationFlowsPolicy (v1.0 by default; beta when -ForceBeta or when v1.0 retrieval fails) and converts it to the TMF shape. Returns object unless -OutPutPath is supplied.
.PARAMETER SpecificResources
Optional filter by display name (wildcards allowed). Singleton; normally not required.
.PARAMETER OutPutPath
Root folder to write export; when omitted the object is returned.
.PARAMETER ForceBeta
Use beta endpoint (always) or as fallback when v1.0 is empty/unsupported.
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAuthenticationFlowsPolicy -OutPutPath C:\tmf
.EXAMPLE
Export-TmfAuthenticationFlowsPolicy | ConvertTo-Json -Depth 15
#>
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/authenticationFlowsPolicies'
        $fileName = 'authenticationFlowsPolicies.json'
        $graphV1 = $script:graphBaseUrl1
        $graphBeta = $script:graphBaseUrl
        function Convert-AuthenticationFlowsPolicy { param([object]$policy) $o = [ordered]@{ present = $true }; if ($policy.displayName) { $o.displayName = $policy.displayName }; if ($policy.selfServiceSignUp -and $null -ne $policy.selfServiceSignUp.isEnabled) { $o.selfServiceSignUpEnabled = [bool]$policy.selfServiceSignUp.isEnabled }; [pscustomobject]$o }
    }
    process {
        $policy = $null; $usedBeta = $false
        if (-not $ForceBeta) { try { $policy = Invoke-MgGraphRequest -Method GET -Uri "$graphV1/policies/authenticationFlowsPolicy" } catch { Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message) } }
        if ($ForceBeta -or -not $policy) { try { $policy = Invoke-MgGraphRequest -Method GET -Uri "$graphBeta/policies/authenticationFlowsPolicy"; $usedBeta = $true } catch { Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message) } }
        if (-not $policy) { if (-not $OutPutPath) { return @() } else { return } }
        $exportObject = Convert-AuthenticationFlowsPolicy $policy
        if ($SpecificResources -and ($SpecificResources -notcontains $exportObject.displayName) -and ($SpecificResources -notcontains '*')) { if (-not $OutPutPath) { return @() } else { return } }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationFlowsPolicy' -Message ("Exporting authentication flows policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta,$usedBeta)
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
