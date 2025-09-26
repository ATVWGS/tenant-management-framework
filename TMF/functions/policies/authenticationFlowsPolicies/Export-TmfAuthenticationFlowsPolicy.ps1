function Export-TmfAuthenticationFlowsPolicy {
    <#
    .SYNOPSIS
    Retrieves the singleton authenticationFlowsPolicy (v1.0 by default; beta when -ForceBeta or when v1.0 retrieval fails) and converts it to the TMF shape. Returns object unless -OutPath is supplied. (Legacy alias: -OutPutPath)
    .PARAMETER SpecificResources
    Optional filter by display name (wildcards allowed). Singleton; normally not required.
    .PARAMETER OutPath
    Root folder to write export; when omitted the object is returned. (Legacy alias: -OutPutPath)
    .PARAMETER ForceBeta
    Use beta endpoint (always) or as fallback when v1.0 is empty/unsupported.
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfAuthenticationFlowsPolicy -OutPath C:\tmf
    .EXAMPLE
    Export-TmfAuthenticationFlowsPolicy | ConvertTo-Json -Depth 15
    #>
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'authenticationFlowsPolicies'
        $parentName = 'policies'
        function Convert-AuthenticationFlowsPolicy {
            param([object]$policy) $o = [ordered]@{ present = $true }; if ($policy.displayName) {
                $o.displayName = $policy.displayName
            }; if ($policy.selfServiceSignUp -and $null -ne $policy.selfServiceSignUp.isEnabled) {
                $o.selfServiceSignUpEnabled = [bool]$policy.selfServiceSignUp.isEnabled
            }; [pscustomobject]$o
        }
    }
    process {
        $policy = $null; $usedBeta = $false
        if (-not $ForceBeta) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl1/policies/authenticationFlowsPolicy"
            } catch {
                Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message)
            }
        }
        if ($ForceBeta -or -not $policy) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrlbeta/policies/authenticationFlowsPolicy"; $usedBeta = $true
            } catch {
                Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message)
            }
        }
        if (-not $policy) {
            if (-not $OutPath) {
                return @()
            } else {
                return
            }
        }
        $exportObject = Convert-AuthenticationFlowsPolicy $policy
        if ($SpecificResources -and ($SpecificResources -notcontains $exportObject.displayName) -and ($SpecificResources -notcontains '*')) {
            if (-not $OutPath) {
                return @()
            } else {
                return
            }
        }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthenticationFlowsPolicy' -Message ("Exporting authentication flows policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta, $usedBeta)
    }
    end {
        if (-not $OutPath) {
            return @($exportObject)
        }
        Write-TmfExportFile -OutPath $OutPath -ParentPath $parentName -ResourceName $resourceName -Data @($exportObject)
    }
}
