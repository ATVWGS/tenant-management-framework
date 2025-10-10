function Write-TmfExportFile {
    <#!
    .SYNOPSIS
    Writes TMF export data to the standard folder / file structure.
    .DESCRIPTION
    Central helper to remove repeated directory creation and JSON serialization logic in Export-* functions.
    Creates (if needed) the directory tree:
    <OutPath>\[<ParentPath>\]<ResourceName>\
    And writes the data to <FileName> (default: <ResourceName>.json) as UTF-8 JSON (configurable depth & encoding).
    If -OutPath is not provided (empty / null), no file is written. Caller typically handles returning objects in that case.
    .PARAMETER OutPath
    Root export folder provided by the user (from the Export-* function's -OutPath parameter).
    .PARAMETER ResourceName
    Logical resource name; becomes the leaf directory and (by default) the file name (with .json suffix).
    .PARAMETER Data
    The object/array to serialize.
    .PARAMETER ParentPath
    Optional relative parent folder (e.g. 'roleManagement' or 'entitlementManagement'). If supplied, it is created beneath OutPath before the resource folder.
    .PARAMETER Depth
    ConvertTo-Json depth (default 15 to match existing exporters).
    .PARAMETER FileName
    Explicit file name (defaults to <ResourceName>.json).
    .PARAMETER Encoding
    Text encoding (default 'utf8').
    .PARAMETER Append
    Add content to existing file
    .PARAMETER PassThru
    When set, returns the written file path. Otherwise produces no output.
    .EXAMPLE
    Write-TmfExportFile -OutPath C:\tmf -ResourceName users -Data $users
    Writes C:\tmf\users\users.json
    .EXAMPLE
    Write-TmfExportFile -OutPath C:\tmf -ParentPath roleManagement -ResourceName roleAssignments -Data $roleAssignments -PassThru
    Writes C:\tmf\roleManagement\roleAssignments\roleAssignments.json and returns its path.
    .NOTES
    Intentionally does not return the input data (only optional file path) to keep caller return semantics explicit.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $OutPath,
        [Parameter(Mandatory)][string] $ResourceName,
        [Parameter(Mandatory)][object] $Data,
        [string] $ParentPath,
        [int] $Depth = 15,
        [string] $FileName,
        [string] $Encoding = 'utf8',
        [switch] $Append,
        [switch] $PassThru
    )

    if (-not $OutPath) {
        return
    } # Caller already handles returning objects when OutPath not set

    # Build base path (root + optional parent folder)
    $baseDir = $OutPath
    if ($ParentPath) {
        $baseDir = Join-Path $baseDir $ParentPath
    }

    if (-not (Test-Path -LiteralPath $baseDir)) {
        New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
    }

    $targetDir = Join-Path $baseDir $ResourceName
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $effectiveFileName = if ($FileName) {
        $FileName
    } else {
        "$ResourceName.json"
    }
    $filePath = Join-Path $targetDir $effectiveFileName

    try {
        if ($Append) {
            $existingData = Get-Content -Path $filePath | ConvertFrom-Json -Depth $Depth
            $combinedExport = $existingData
            $combinedExport += $Data
            $combinedExport | ConvertTo-Json -Depth $Depth | Out-File -FilePath $filePath -Encoding $Encoding -Force
        }
        else {
            $Data | ConvertTo-Json -Depth $Depth | Out-File -FilePath $filePath -Encoding $Encoding -Force
        }        
        Write-PSFMessage -Level Verbose -FunctionName 'Write-TmfExportFile' -Message "Wrote export file: $filePath"
    } catch {
        Write-PSFMessage -Level Warning -FunctionName 'Write-TmfExportFile' -Message ("Failed writing export file {0}: {1}" -f $filePath, $_.Exception.Message)
        throw
    }

    if ($PassThru) {
        return $filePath
    }
}
