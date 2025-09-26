<#
.SYNOPSIS
Exports Azure AD groups into TMF configuration objects or JSON.
.DESCRIPTION
Retrieves groups via Microsoft Graph (v1.0 by default; beta when -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied, in which case JSON is written to groups/groups.json.
.PARAMETER SpecificResources
Optional list of group display names or IDs (comma separated accepted) to filter.
.PARAMETER OutPath
Root folder to write the export. When omitted, objects are returned instead of writing files. Legacy alias -OutPutPath is deprecated.
.PARAMETER ForceBeta
Use beta Graph endpoint for retrieval (may expose additional properties).
.PARAMETER Cmdlet
Internal pipeline parameter; do not supply manually.
.EXAMPLE
Export-TmfGroup -OutPath C:\temp\tmf
.EXAMPLE
Export-TmfGroup -SpecificResources "HR Group","1234-5678" | ConvertTo-Json -Depth 15
#>
function Export-TmfGroup {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'groups'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $groupsExport = @()
        $select = 'id,displayName,description,groupTypes,securityEnabled,mailEnabled,visibility,mailNickname'
        function Convert-Group {
            param([object]$g) [ordered]@{ displayName = $g.displayName; description = $g.description; groupTypes = $g.groupTypes; securityEnabled = $g.securityEnabled; mailEnabled = $g.mailEnabled; visibility = $g.visibility; mailNickname = $g.mailNickname; present = $true } 
        }
        function Get-AllGroups {
            $list = @()
            $resp = Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/groups?`$top=999&`$select=$select"
            if ($resp.keys -contains '@odata.nextLink') {
                do {
                    $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } while ($resp.'@odata.nextLink')
            } else {
                $list += $resp.value 
            }
            return $list
        }
    }
    process {
        if ($SpecificResources) {
            $identifiers = @(); foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $identifiers = $identifiers | Select-Object -Unique
            $allGroups = Get-AllGroups
            foreach ($idOrName in $identifiers) {
                $match = $allGroups | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) {
                        $groupsExport += Convert-Group $m 
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfGroup' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                }
            }
        } else {
            foreach ($g in (Get-AllGroups)) {
                $groupsExport += Convert-Group $g 
            } 
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfGroup' -Message "Exporting $($groupsExport.Count) group(s). ForceBeta=$ForceBeta"
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $groupsExport
        } else {
            return $groupsExport
        }
    }
}
