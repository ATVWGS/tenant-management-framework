function Export-TmfAppManagementPolicy {
    <#
        .SYNOPSIS
            Exports app management policies from the tenant.

        .DESCRIPTION
            Retrieves appManagementPolicies collection from Microsoft Graph and converts them
            into the TMF desired configuration shape. Writes to policies/appManagementPolicies/appManagementPolicies.json
            when OutPutPath is provided, or returns the objects when omitted.

        .PARAMETER SpecificResources
            Optional filter by display name. Can include wildcards; matches are applied client-side.

        .PARAMETER OutPutPath
            Destination root folder to write the exported configuration.

        .PARAMETER Cmdlet
            The invoking cmdlet. Defaults to the current $PSCmdlet.

        .EXAMPLE
            Export-TmfAppManagementPolicy -OutPutPath "C:\Temp\tmf-config"

        .EXAMPLE
            Export-TmfAppManagementPolicy | ConvertTo-Json -Depth 15
    #>
    [CmdletBinding()]
    Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/appManagementPolicies'
        $fileName = 'appManagementPolicies.json'

        function Convert-AppManagementPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy,
                [string[]] $appliesToIds
            )

            $obj = [ordered]@{ present = $true }

            foreach ($p in @('id','displayName','description','isEnabled')) {
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p -and $policy.$p -ne '') { $obj[$p] = $policy.$p }
            }

            if ($policy.PSObject.Members.Match('restrictions') -and $null -ne $policy.restrictions) {
                $obj.restrictions = $policy.restrictions
            }

            if ($appliesToIds -and $appliesToIds.Count -gt 0) { $obj.appliesTo = $appliesToIds }

            return [pscustomobject]$obj
        }

        function Get-AllAppManagementPolicies {
            $all = @(); $usedBeta=$false
            $v1Uri = "$script:graphBaseUrl1/policies/appManagementPolicies"
            $resp = $null
            if (-not $ForceBeta) {
                try { $resp = Invoke-MgGraphRequest -Method GET -Uri $v1Uri } catch { Write-PSFMessage -Level Verbose -Message ('v1.0 appManagementPolicies retrieval failed: {0}' -f $_.Exception.Message) }
            }
            if ($ForceBeta -or -not $resp) {
                try { $resp = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/policies/appManagementPolicies"; $usedBeta=$true } catch { Write-PSFMessage -Level Verbose -Message ('beta appManagementPolicies retrieval failed: {0}' -f $_.Exception.Message) }
            }
            if (-not $resp) { return @() }
            do { if ($resp.value) { $all += $resp.value }; $next=$resp.'@odata.nextLink'; if ($next) { try { $resp = Invoke-MgGraphRequest -Method GET -Uri $next } catch { Write-PSFMessage -Level Verbose -Message ('Pagination fetch failed: {0}' -f $_.Exception.Message); break } } } while ($next)
            Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAppManagementPolicy' -Message ("Retrieved {0} appManagementPolicies (UsedBeta={1} ForceBeta={2})" -f $all.Count,$usedBeta,$ForceBeta)
            return $all
        }
    }
    process {
        $policies = Get-AllAppManagementPolicies
        if (-not $policies) { if (-not $OutPutPath) { return @() } else { $export = @() } }

        if ($SpecificResources) {
            $filters = @()
            foreach ($entry in $SpecificResources) { $filters += ($entry -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
            $filters = $filters | Select-Object -Unique
            $policies = $policies | Where-Object { $name = $_.displayName; ($filters | Where-Object { $name -like $_ }).Count -gt 0 }
        }

        $export = @()
        foreach ($p in $policies) {
            # Get appliesTo for each policy (ids)
            $appliesToIds = @()
            try {
                $rel = Invoke-MgGraphRequest -Method GET -Uri ("{0}/policies/appManagementPolicies/{1}/appliesTo" -f (if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }), $p.id)
                if ($rel.value) { $appliesToIds = $rel.value.id }
            }
            catch {
                Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAppManagementPolicy' -Message "Failed to fetch appliesTo for policy $($p.id): $_"
            }

            $export += (Convert-AppManagementPolicy -policy $p -appliesToIds $appliesToIds)
        }

    if (-not $OutPutPath) { return $export }
    }
    end {
        if ($OutPutPath) {
            $targetDir = Join-Path -Path $OutPutPath -ChildPath $resourceFolder
            if (-not (Test-Path -LiteralPath (Join-Path $OutPutPath 'policies'))) {
                New-Item -ItemType Directory -Path (Join-Path $OutPutPath 'policies') -Force | Out-Null
            }
            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            }

            $export | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir $fileName) -Encoding utf8 -Force
        }
    }
}
