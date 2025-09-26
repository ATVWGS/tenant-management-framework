
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
    }
    process {
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
            $obj = [ordered]@{}
            foreach ($p in $agreement.GetEnumerator()) {
                if ($p.Value -and $p.Key -ne "files") {
                    $obj[$p.Key] = $p.Value
                }
            }
            $obj["files"] = @()
            $obj["present"] = $true
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
                        $targetPath = Join-Path -Path $filesFolder -ChildPath $loc.fileName
                        $relativePath = 'files/' + [IO.Path]::GetFileName($targetPath) 
                        $obj.files += [ordered]@{ fileName = $loc.fileName; language = $loc.language; isDefault = $loc.isDefault; filePath = $relativePath }
                        if ($OutPath) {
                            try {
                                $filePath = $targetPath 
                                $fileDataResponse = Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/file/localizations/$($loc.id)/filedata/data" -ContentType "application/json"
                                $fileBytes = [Convert]::FromBase64String($fileDataResponse.value)
                                [System.IO.File]::WriteAllBytes($filePath, $fileBytes)
                            } catch {
                                Write-PSFMessage -Level Warning -String 'TMF.Export.FileDownloadFailed' -StringValues $loc.fileName, $_.Exception.Message 
                            } 
                        } 
                    } 
                }
                if (-not $localizations) {
                    $files = (Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/files?`$select=id,fileName,language,isDefault").value; if ($files) {
                        foreach ($file in $files) {
                            $targetPath = Join-Path -Path $filesFolder -ChildPath $file.fileName
                            $relativePath = 'files/' + [IO.Path]::GetFileName($targetPath) 
                            
                            $obj.files += [ordered]@{ fileName = $file.fileName; language = $file.language; isDefault = $file.isDefault; filePath = $relativePath }
                            if ($OutPath) {
                                try {
                                    $filePath = $targetPath

                                    $fileDataResponse = Invoke-MgGraphRequest -Method GET -Uri "$graph/agreements/$($agreement.id)/files/$($file.id)/filedata/data" -ContentType "application/json"
                                    $fileBytes = [Convert]::FromBase64String($fileDataResponse.value)
                                    [System.IO.File]::WriteAllBytes($filePath, $fileBytes)
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
