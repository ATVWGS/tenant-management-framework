<#
.SYNOPSIS
Exports Azure AD groups into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves groups via Microsoft Graph (v1.0 by default; beta when -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPutPath is supplied, in which case JSON is written to groups/groups.json.
.PARAMETER SpecificResources
Optional list of group display names or IDs (comma separated accepted) to filter.
.PARAMETER OutPutPath
Root folder to write the export. When omitted, objects are returned instead of writing files.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfGroup -OutPutPath C:\temp\tmf
.EXAMPLE
Export-TmfGroup -SpecificResources "HR Group","1234-5678" | ConvertTo-Json -Depth 15
#>
function Export-TmfGroup {
    [CmdletBinding()] Param(
        [string[]] $SpecificResources,
        [string] $OutPutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'groups'
        $graphBase = if ($ForceBeta) { $script:graphBaseUrl } else { $script:graphBaseUrl1 }
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$graphBase/organization?`$select=displayname,id")).value
        $groupsExport = @()
        $select = 'id,displayName,description,groupTypes,securityEnabled,mailEnabled,visibility,mailNickname'
        function Convert-Group { param([object]$g) [ordered]@{ displayName=$g.displayName; description=$g.description; groupTypes=$g.groupTypes; securityEnabled=$g.securityEnabled; mailEnabled=$g.mailEnabled; visibility=$g.visibility; mailNickname=$g.mailNickname; present=$true } }
        function Get-AllGroups {
            $list = @()
            $resp = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/groups?`$top=999&`$select=$select"
            if ($resp.keys -contains '@odata.nextLink') {
                do { $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' } while ($resp.'@odata.nextLink')
            } else { $list += $resp.value }
            return $list
        }
    }
    process {
        if ($SpecificResources) {
            $identifiers = @(); foreach ($entry in $SpecificResources) { $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } }; $identifiers = $identifiers | Select-Object -Unique
            $allGroups = Get-AllGroups
            foreach ($idOrName in $identifiers) {
                $match = $allGroups | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) { foreach ($m in $match) { $groupsExport += Convert-Group $m } } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfGroup' -String 'TMF.Export.NotFound' -StringValues $idOrName,$resourceName,$tenant.displayName }
            }
        } else { foreach ($g in (Get-AllGroups)) { $groupsExport += Convert-Group $g } }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfGroup' -Message "Exporting $($groupsExport.Count) group(s). ForceBeta=$ForceBeta"
        if (-not $OutPutPath) { return $groupsExport }
        $targetDir = Join-Path -Path $OutPutPath -ChildPath $resourceName
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        $groupsExport | ConvertTo-Json -Depth 15 | Out-File -FilePath (Join-Path $targetDir "$resourceName.json") -Encoding utf8 -Force
    }
}