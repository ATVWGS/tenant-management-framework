
<#
.SYNOPSIS
Exports agreements and associated files.
.DESCRIPTION
Retrieves agreements (v1.0) with optional fallback listing and downloads localized files via multiple strategies (with optional beta fallback for content). Returns objects unless -OutPath supplied.
.PARAMETER SpecificResources
Optional list of agreement IDs or display names (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write export; when omitted objects are returned (files not downloaded). Legacy alias -OutPutPath is deprecated.
.PARAMETER ForceBeta
Use beta endpoint for metadata retrieval (still attempts v1.0 first where stable); file strategies continue to fall back as needed.
.PARAMETER AllowBetaContentFallback
Permit beta endpoint attempts for file content if v1.0 paths fail.
.PARAMETER ContinueOnListFailure
Continue execution even if initial listing fails (may yield empty output).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfAgreement -OutPath C:\temp\tmf -AllowBetaContentFallback
.EXAMPLE
Export-TmfAgreement -SpecificResources 'Privacy Policy' -OutPath C:\temp\tmf
#>
function Export-TmfAgreement {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [switch] $AllowBetaContentFallback,
        [switch] $ContinueOnListFailure,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'agreements'
        $agreementsExport = @()
        $graph = if ($ForceBeta) {
            $script:graphBaseUrlBeta 
        } else {
            $script:graphBaseUrl1 
        }
        $graphBeta = $script:graphBaseUrlBeta
        $graphIG = "$graph/identityGovernance/termsOfUse"
        $graphIGBeta = "$graphBeta/identityGovernance/termsOfUse"
        try {
            $ctx = Get-MgContext -ErrorAction Stop; if ($ctx -and $ctx.Scopes -and -not ($ctx.Scopes | Where-Object { $_ -like 'Agreement.*' })) {
                Write-PSFMessage -Level Verbose -Message 'Current token scopes lack Agreement.*; downloads may fail.' 
            } 
        } catch { 
        }
        function Test-DownloadedFile {
            param([string]$Path) try {
                if (-not (Test-Path -LiteralPath $Path)) {
                    return $false 
                }; $f = Get-Item -LiteralPath $Path -ErrorAction Stop; return [bool]($f.Length -gt 0) 
            } catch {
                return $false 
            } 
        }
        function Test-IsPdf {
            param([string]$Path) try {
                if (-not (Test-Path -LiteralPath $Path)) {
                    return $false 
                }; $bytes = Get-Content -LiteralPath $Path -Encoding Byte -TotalCount 4 -ErrorAction Stop; if (-not $bytes -or $bytes.Count -lt 4) {
                    return $false 
                }; $sig = [System.Text.Encoding]::ASCII.GetString($bytes); return ($sig -eq '%PDF') 
            } catch {
                return $false 
            } 
        }
        function Test-ValidDownloadedFile {
            param([string]$Path, [string]$ExpectedFileName) try {
                if (-not (Test-Path -LiteralPath $Path)) {
                    return $false 
                }; $f = Get-Item -LiteralPath $Path -ErrorAction Stop; if (-not $f -or $f.Length -le 0) {
                    return $false 
                }; $ext = if ($ExpectedFileName) {
                    [IO.Path]::GetExtension($ExpectedFileName) 
                } else {
                    '' 
                }; if ($ext -and $ext.Trim().ToLower() -eq '.pdf') {
                    return (Test-IsPdf -Path $Path) 
                }; return $true 
            } catch {
                return $false 
            } 
        }
        function Get-HttpErrorDetails {
            param($ErrorRecord) try {
                $msg = $ErrorRecord.Exception.Message; $resp = $ErrorRecord.Exception.Response; if ($resp -and $resp.StatusCode) {
                    $msg = "Status=$([string]$resp.StatusCode); Message=$msg" 
                }; return $msg 
            } catch {
                return $ErrorRecord.Exception.Message 
            } 
        }
        function Get-UniqueFilePath {
            param([string]$Folder, [string]$FileName, [string]$Language) $candidate = Join-Path -Path $Folder -ChildPath $FileName; if (-not (Test-Path -LiteralPath $candidate)) {
                return $candidate 
            }; $base = [IO.Path]::GetFileNameWithoutExtension($FileName); $ext = [IO.Path]::GetExtension($FileName); if ($Language) {
                $langPart = $Language -replace "[^A-Za-z0-9-]", "-"; $candidateLang = Join-Path -Path $Folder -ChildPath ("{0}.{1}{2}" -f $base, $langPart, $ext); if (-not (Test-Path -LiteralPath $candidateLang)) {
                    return $candidateLang 
                } 
            }; $i = 1; while ($true) {
                $candidateNum = Join-Path -Path $Folder -ChildPath ("{0} ({1}){2}" -f $base, $i, $ext); if (-not (Test-Path -LiteralPath $candidateNum)) {
                    return $candidateNum 
                }; $i++ 
            } 
        }
    }
    process {
        Write-TmfDeprecatedParameterWarning -InvocationLine $MyInvocation.Line -LegacyParameter 'OutPutPath' -NewParameter 'OutPath'
        if ($OutPath) {
            $resourceFolderPath = Join-Path -Path $OutPath -ChildPath $resourceName; if (-not (Test-Path $resourceFolderPath)) {
                New-Item -Path $resourceFolderPath -ItemType Directory -Force | Out-Null 
            }; $filesFolder = Join-Path -Path $resourceFolderPath -ChildPath 'files'; if (-not (Test-Path $filesFolder)) {
                New-Item -Path $filesFolder -ItemType Directory -Force | Out-Null; Write-PSFMessage -Level Verbose -String 'TMF.Export.CreatedDirectory' -StringValues $filesFolder 
            } 
        }
        $allAgreements = @(); $uri = "$graph/agreements?`$select=id,displayName,isViewingBeforeAcceptanceRequired,isPerDeviceAcceptanceRequired,userReacceptRequiredFrequency,termsExpiration"; try {
            while ($uri) {
                $resp = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop; if ($resp.value) {
                    $allAgreements += $resp.value 
                }; $uri = $resp.'@odata.nextLink' 
            } 
        } catch {
            $igListSucceeded = $false; try {
                Write-PSFMessage -Level Verbose -Message 'Attempting fallback listing via identityGovernance path'; $igUri = "$graphIG/agreements?`$select=id,displayName,isViewingBeforeAcceptanceRequired,isPerDeviceAcceptanceRequired,userReacceptRequiredFrequency,termsExpiration"; while ($igUri) {
                    $respIG = Invoke-MgGraphRequest -Method GET -Uri $igUri -ErrorAction Stop; if ($respIG.value) {
                        $allAgreements += $respIG.value 
                    }; $igUri = $respIG.'@odata.nextLink' 
                }; if ($allAgreements.Count -gt 0) {
                    $igListSucceeded = $true 
                } 
            } catch { 
            } if (-not $ContinueOnListFailure -and -not $igListSucceeded) {
                throw 
            } elseif (-not $igListSucceeded) {
                Write-PSFMessage -Level Warning -Message 'Continuing despite agreement list failure.' 
            } 
        }
        if ($SpecificResources) {
            $ids = @(); foreach ($e in $SpecificResources) {
                $ids += $e -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $ids = $ids | Select-Object -Unique; $allAgreements = $allAgreements | Where-Object { $ids -contains $_.id -or $ids -contains $_.displayName } 
        }
        foreach ($agreement in $allAgreements) {
            $obj = [ordered]@{ displayName = $agreement.displayName; isViewingBeforeAcceptanceRequired = $agreement.isViewingBeforeAcceptanceRequired; isPerDeviceAcceptanceRequired = $agreement.isPerDeviceAcceptanceRequired; userReacceptRequiredFrequency = $agreement.userReacceptRequiredFrequency; termsExpiration = $agreement.termsExpiration; files = @(); present = $true }
            try {
                try {
                    $localizations = (Invoke-MgGraphRequest -Method GET -Uri "$graphIG/agreements/$($agreement.id)/file/localizations?`$select=id,fileName,language,isDefault").value; if (-not $localizations) {
                        $localizations = (Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/file/localizations?`$select=id,fileName,language,isDefault").value 
                    } if (-not $localizations) {
                        $igFiles = (Invoke-MgGraphRequest -Method GET -Uri "$graphIG/agreements/$($agreement.id)/files?`$select=id,displayName").value; foreach ($igFile in ($igFiles | Where-Object { $_ })) {
                            $fileLocs = (Invoke-MgGraphRequest -Method GET -Uri "$graphIG/agreements/$($agreement.id)/files/$($igFile.id)/localizations?`$select=id,fileName,language,isDefault").value; if (-not $fileLocs) {
                                $fileLocs = (Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/files/$($igFile.id)/localizations?`$select=id,fileName,language,isDefault").value 
                            }; if ($fileLocs) {
                                $localizations += $fileLocs 
                            } 
                        } 
                    } 
                } catch { 
                }
                if ($localizations) {
                    foreach ($loc in $localizations) {
                        $targetPath = $null; if ($OutPath) {
                            $targetPath = Get-UniqueFilePath -Folder $filesFolder -FileName $loc.fileName -Language $loc.language 
                        }; $relativePath = if ($targetPath) {
                            'files/' + [IO.Path]::GetFileName($targetPath) 
                        } else {
                            "files/$($loc.fileName)" 
                        }; $obj.files += [ordered]@{ fileName = $loc.fileName; language = $loc.language; isDefault = $loc.isDefault; filePath = $relativePath }; if ($OutPath) {
                            try {
                                $filePath = $targetPath; $downloaded = $false; $lastErr = $null; $attempt = $null; foreach ($attemptInfo in @(
                                        @{ a = 'v1.0 IG localization direct'; u = "$graphIG/agreements/$($agreement.id)/file/localizations/$($loc.id)" },
                                        @{ a = 'v1.0 IG localization $value'; u = "$graphIG/agreements/$($agreement.id)/file/localizations/$($loc.id)/`$value" },
                                        @{ a = 'v1.0 IG localization versions list'; u = "$graphIG/agreements/$($agreement.id)/file/localizations/$($loc.id)/versions?`$select=id,createdDateTime&`$orderby=createdDateTime%20desc&`$top=1"; list = $true },
                                        @{ a = 'v1.0 IG localization documentStream'; u = "$graphIG/agreements/$($agreement.id)/file/localizations/$($loc.id)/documentStream" },
                                        @{ a = 'v1.0 legacy localization $value'; u = "$graph/agreements/$($agreement.id)/file/localizations/$($loc.id)/`$value" }
                                    )) {
                                    if ($downloaded) {
                                        break 
                                    }
                                    $attempt = $attemptInfo.a
                                    try {
                                        if ($attemptInfo.list) {
                                            $versIG = Invoke-MgGraphRequest -Method GET -Uri $attemptInfo.u; if ($versIG.value.Count -gt 0) {
                                                $latestId = $versIG.value[0].id; foreach ($vtry in @(
                                                        "$graphIG/agreements/$($agreement.id)/file/localizations/$($loc.id)/versions/$latestId/`$value",
                                                        "$graphIG/agreements/$($agreement.id)/file/localizations/$($loc.id)/versions/$latestId/content"
                                                    )) {
                                                    if ($downloaded) {
                                                        break 
                                                    }; try {
                                                        Invoke-MgGraphRequest -Method GET -Uri $vtry -Headers @{ Accept = 'application/octet-stream' } -OutputFilePath $filePath -ErrorAction Stop | Out-Null; $downloaded = Test-ValidDownloadedFile -Path $filePath -ExpectedFileName $loc.fileName 
                                                    } catch {
                                                        $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                                    } 
                                                } 
                                            } 
                                        } else {
                                            Invoke-MgGraphRequest -Method GET -Uri $attemptInfo.u -Headers @{ Accept = 'application/octet-stream' } -OutputFilePath $filePath -ErrorAction Stop | Out-Null; $downloaded = Test-ValidDownloadedFile -Path $filePath -ExpectedFileName $loc.fileName 
                                        }
                                    } catch {
                                        $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                    }
                                }
                                if (-not $downloaded -and $AllowBetaContentFallback) {
                                    foreach ($bAttempt in @(
                                            "$graphIGBeta/agreements/$($agreement.id)/file/localizations/$($loc.id)/`$value"
                                        )) {
                                        if ($downloaded) {
                                            break 
                                        }; try {
                                            Invoke-MgGraphRequest -Method GET -Uri $bAttempt -Headers @{ Accept = 'application/octet-stream' } -OutputFilePath $filePath -ErrorAction Stop | Out-Null; $downloaded = Test-ValidDownloadedFile -Path $filePath -ExpectedFileName $loc.fileName 
                                        } catch {
                                            $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                        } 
                                    } 
                                }
                                if ($downloaded) {
                                    Write-PSFMessage -Level Verbose -String 'TMF.Export.FileDownloadSuccess' -StringValues $loc.fileName, $filePath 
                                } else {
                                    $reason = if ($lastErr) {
                                        $lastErr 
                                    } else {
                                        'No content returned' 
                                    }; Write-PSFMessage -Level Warning -String 'TMF.Export.FileDownloadFailed' -StringValues $loc.fileName, $reason; if (Test-Path -LiteralPath $filePath) {
                                        Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue 
                                    } 
                                } 
                            } catch {
                                Write-PSFMessage -Level Warning -String 'TMF.Export.FileDownloadFailed' -StringValues $loc.fileName, $_.Exception.Message 
                            } 
                        } 
                    } 
                }
                if (-not $localizations) {
                    $files = (Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/files?`$select=id,fileName,language,isDefault").value; if ($files) {
                        foreach ($file in $files) {
                            $targetPath = $null; if ($OutPath) {
                                $targetPath = Get-UniqueFilePath -Folder $filesFolder -FileName $file.fileName -Language $file.language 
                            }; $relativePath = if ($targetPath) {
                                'files/' + [IO.Path]::GetFileName($targetPath) 
                            } else {
                                "files/$($file.fileName)" 
                            }; $obj.files += [ordered]@{ fileName = $file.fileName; language = $file.language; isDefault = $file.isDefault; filePath = $relativePath }; if ($OutPath) {
                                try {
                                    $filePath = $targetPath; $downloaded = $false; $lastErr = $null; foreach ($try in @(
                                            "$graph/agreements/$($agreement.id)/files/$($file.id)/documentStream",
                                            "$graph/agreements/$($agreement.id)/files/$($file.id)/`$value"
                                        )) {
                                        if ($downloaded) {
                                            break 
                                        }; try {
                                            Invoke-MgGraphRequest -Method GET -Uri $try -OutputFilePath $filePath -ErrorAction Stop | Out-Null; $downloaded = Test-DownloadedFile -Path $filePath 
                                        } catch {
                                            $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                        } 
                                    }; if (-not $downloaded) {
                                        try {
                                            $fvers = Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/files/$($file.id)/versions?`$select=id,createdDateTime"; if ($fvers.value.Count -gt 0) {
                                                $flatest = ($fvers.value | Sort-Object -Property createdDateTime -Descending | Select-Object -First 1); foreach ($verTry in @(
                                                        "$graph/agreements/$($agreement.id)/files/$($file.id)/versions/$($flatest.id)/content"
                                                    )) {
                                                    if ($downloaded) {
                                                        break 
                                                    }; try {
                                                        Invoke-MgGraphRequest -Method GET -Uri $verTry -OutputFilePath $filePath -ErrorAction Stop | Out-Null; $downloaded = Test-DownloadedFile -Path $filePath 
                                                    } catch {
                                                        $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                                    } 
                                                } 
                                            } 
                                        } catch {
                                            $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                        } 
                                    } if (-not $downloaded -and $AllowBetaContentFallback) {
                                        foreach ($btry in @(
                                                "$graphBeta/agreements/$($agreement.id)/files/$($file.id)/documentStream",
                                                "$graphBeta/agreements/$($agreement.id)/files/$($file.id)/`$value"
                                            )) {
                                            if ($downloaded) {
                                                break 
                                            }; try {
                                                Invoke-MgGraphRequest -Method GET -Uri $btry -OutputFilePath $filePath -ErrorAction Stop | Out-Null; $downloaded = Test-DownloadedFile -Path $filePath 
                                            } catch {
                                                $lastErr = Get-HttpErrorDetails -ErrorRecord $_ 
                                            } 
                                        } 
                                    }; if ($downloaded) {
                                        Write-PSFMessage -Level Verbose -String 'TMF.Export.FileDownloadSuccess' -StringValues $file.fileName, $filePath 
                                    } else {
                                        $reason = if ($lastErr) {
                                            $lastErr 
                                        } else {
                                            'No content returned' 
                                        }; Write-PSFMessage -Level Warning -String 'TMF.Export.FileDownloadFailed' -StringValues $file.fileName, $reason; if (Test-Path -LiteralPath $filePath) {
                                            Remove-Item -LiteralPath $filePath -Force -ErrorAction SilentlyContinue 
                                        } 
                                    } 
                                } catch {
                                    Write-PSFMessage -Level Warning -String 'TMF.Export.FileDownloadFailed' -StringValues $file.fileName, $_.Exception.Message 
                                } 
                            } 
                        } 
                    } 
                }
            } catch {
                Write-PSFMessage -Level Warning -String 'TMF.Export.FileRetrievalFailed' -StringValues $agreement.displayName, $_.Exception.Message 
            }
            $agreementsExport += $obj
        }
        if (-not $OutPath) {
            return $agreementsExport 
        }
    }
    end {
        if (-not $OutPath) {
            return 
        }
        $resourceFolderPath = Join-Path -Path $OutPath -ChildPath $resourceName
        if (-not (Test-Path $resourceFolderPath)) {
            New-Item -Path $resourceFolderPath -ItemType Directory -Force | Out-Null 
        }
        $agreementsExport | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $resourceFolderPath "$resourceName.json") -Encoding utf8 -Force
        Write-PSFMessage -Level Verbose -String 'TMF.Export.Completed' -StringValues $resourceName
    }
}
