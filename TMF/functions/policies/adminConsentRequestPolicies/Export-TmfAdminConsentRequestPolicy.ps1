<#
.SYNOPSIS
Exports the tenant default app management policy into TMF configuration object or JSON.
.DESCRIPTION
Retrieves the default adminConsentRequestPolicy singleton (v1.0 by default; beta when -ForceBeta) and converts it to the TMF shape. Returns object unless -OutPath is supplied.
.PARAMETER OutPath
Root folder to write the export. When omitted, object is returned instead of writing files. Legacy alias -OutPutPath is deprecated.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAdminConsentRequestPolicy -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfAdminConsentRequestPolicy | ConvertTo-Json -Depth 15
#>
function Export-TmfAdminConsentRequestPolicy {
    [CmdletBinding()] Param(
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceFolder = 'policies/adminConsentRequestPolicy'
        $fileName = 'adminConsentRequestPolicy.json'

        function Convert-AdminConsentRequestPolicy {
            param(
                [Parameter(Mandatory)] [object] $policy
            )

            $obj = [ordered]@{ present = $true; displayName = "adminConsentRequestPolicy" }

            foreach ($p in @('notifyReviewers','remindersEnabled','isEnabled','requestDurationInDays')) {
                if ($p -in $policy.keys -and $null -ne $policy.$p ) { $obj[$p] = $policy.$p }
            }

            if ($policy.reviewers) {
                $reviewers = @()
                foreach ($reviewer in $policy.reviewers) {
                    switch -Wildcard ($reviewer.query) {
                        "*users*" {
                            $reviewers += @{
                                "type" = "singleUser"
                                "reference" = Resolve-User -InputReference ($reviewer.query.split("/")[-1]) -UserPrincipalName
                            }
                        }
                        "*groups*" {
                            $reviewers += @{
                                "type" = "groupMembers"
                                "reference" = Resolve-Group -InputReference ($reviewer.query.split("/")[3]) -DisplayName
                            }
                        }
                        "*roleManagement*" {
                            $reviewers += @{
                                "type" = "roleMembers"
                                "reference" = Resolve-DirectoryRoleDefinition -InputReference ($reviewer.query.split("'")[1]) -DisplayName
                            }
                        }
                    }
                }
                $obj["reviewers"] = $reviewers
            }
            else {
                $obj["reviewers"] = @()
            }


            return [pscustomobject]$obj
        }
    }
    process {
        $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
        try { $policy = Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/policies/adminConsentRequestPolicy") } catch { throw $_ }

            if (-not $policy) { return @() }

            $exportObject = Convert-AdminConsentRequestPolicy -policy $policy
            if (-not $OutPath) { return @($exportObject) }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAdminConsentRequestPolicy' -Message "Exporting admin consent request policy. ForceBeta=$ForceBeta"
        if (-not $OutPath) { return @($exportObject) }
        $targetDir = Join-Path -Path $OutPath -ChildPath $resourceFolder
        if (-not (Test-Path -LiteralPath $targetDir)) { if (-not (Test-Path -LiteralPath (Join-Path $OutPath 'policies'))) { New-Item -ItemType Directory -Path (Join-Path $OutPath 'policies') -Force | Out-Null }; New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        @($exportObject) | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir $fileName) -Encoding utf8 -Force
    }
}
