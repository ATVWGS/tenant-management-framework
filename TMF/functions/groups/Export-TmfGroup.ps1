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
        [ValidateSet("Security", "M365", "All")]
        [string] $Scope = "Security",
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'groups'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $groupsExport = @()
        $select = 'id,displayName,description,groupTypes,securityEnabled,isAssignableToRole,mailEnabled,membershipRule,assignedLicenses,mailNickname'
        function Convert-Group {
            param([object]$g, [object]$PAGs) 
            $groupDetails = [ordered]@{displayName = $g.displayName; description = $g.description; groupTypes = $g.groupTypes; securityEnabled = $g.securityEnabled; mailEnabled = $g.mailEnabled; mailNickname = $g.mailNickname}
            if ($g.isAssignableToRole) {
                $groupDetails["isAssignableToRole"] = $g.isAssignableToRole
            }
            if ($g.membershipRule) {
                $groupDetails["membershipRule"] = $g.membershipRule
            }
            if ($g.assignedLicenses) {
                $groupDetails["assignedLicenses"] = $g.assignedLicenses
            }            
            if ($g.id -in $PAGs.externalId) {
                $groupDetails["privilegedAccess"] = $true
            }
            $groupDetails["present"] = $true
            return $groupDetails
        }
        function Get-AllGroups {
            param(
                [Parameter(Mandatory=$true)]
                [string]$Scope,
                [string[]] $SpecificResourceNames,
                [string[]] $SpecificResourceIDs,
                [string[]] $SpecificResourceSearches
            )
            switch ($Scope) {
                "Security" {$filter="&`$filter=mailEnabled eq false AND securityEnabled eq true"}
                "M365" {$filter="&`$filter=groupTypes/any(c:c+eq+'Unified')"}
                "All" {$filter=""}
            }
            $list = @()
            if ($SpecificResourceNames -or $SpecificResourceIDs -or $SpecificResourceSearches) {
                if ($SpecificResourceNames) {
                    $loops = [math]::ceiling($SpecificResourceNames.count/15)
                    $start = 0
                    $end = 14
                    for ($i=1; $i -le $loops; $i++) {
                        $specificFilter = if ($filter) {"$filter AND displayName in ['$($SpecificResourceNames[$start..$end] -join "','")']"} else {"&`$filter=displayName in ['$($SpecificResourceNames[$start..$end] -join "','")']"}
                        $response = (Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/groups?`$top=999&`$select=$select$($specificFilter)").value
                        foreach ($item in $response) {
                            $list += $item
                        }
                        $start += 15
                        $end += 15
                    }
                }
                if ($SpecificResourceIDs) {
                    $loops = [math]::ceiling($SpecificResourceIDs.count/15)
                    $start = 0
                    $end = 14
                    for ($i=1; $i -le $loops; $i++) {
                        $specificFilter = if ($filter) {"$filter AND id in ['$($SpecificResourceIDs[$start..$end] -join "','")']"} else {"&`$filter=id in ['$($SpecificResourceIDs[$start..$end] -join "','")']"}
                        $response = (Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/groups?`$top=999&`$select=$select$($specificFilter)").value
                        foreach ($item in $response) {
                            $list += $item
                        }
                        $start += 15
                        $end += 15
                    }
                }
                $SpecificResourceSearches | ForEach-Object {
                    $specificFilter = if ($filter) {"$filter&`$search=`"displayname:$($_)`""} else {"&`$search=`"displayname:$($_)`""}
                    $response = (Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/groups?`$top=999&`$select=$select$($specificFilter)" -Headers @{"ConsistencyLevel"="eventual"}).value
                    foreach ($item in $response) {
                        $list += $item
                    }
                }
            }
            else {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/groups?`$top=999&`$select=$select$($filter)"
                if ($resp.keys -contains '@odata.nextLink') {
                    do {
                        $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                    } while ($resp.'@odata.nextLink')
                } else {
                    $list += $resp.value 
                }
            }            
            return $list
        }
    }
    process {
        $PAGs=(Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/privilegedAccess/aadGroups/resources?`$select=externalId&`$top=999").value
        if ($SpecificResources) {

            $SpecificResourceIDs = @()
            $SpecificResourceNames = @()
            $SpecificResourceSearches = @()

            foreach ($SpecificResource in $SpecificResources) {
                if ($SpecificResource -match $script:guidRegex) {
                    $SpecificResourceIDs += $SpecificResource
                }
                elseif ($SpecificResource -match "\*") {
                    $SpecificResourceSearches += $SpecificResource.replace("*","")
                }
                else {
                    $SpecificResourceNames += $SpecificResource
                }
            }

            $allGroups = Get-AllGroups -Scope $Scope -SpecificResourceNames $SpecificResourceNames -SpecificResourceIDs $SpecificResourceIDs -SpecificResourceSearches $SpecificResourceSearches
            foreach ($g in $allGroups) {
                $groupsExport += Convert-Group $g $PAGs
            }
            <#
            $identifiers = @(); foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } 
            }; $identifiers = $identifiers | Select-Object -Unique
            $allGroups = Get-AllGroups -Scope $Scope
            foreach ($idOrName in $identifiers) {
                $match = $allGroups | Where-Object { $_.id -eq $idOrName -or $_.displayName -eq $idOrName }
                if ($match) {
                    foreach ($m in $match) {
                        $groupsExport += Convert-Group $m $PAGs
                    } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfGroup' -String 'TMF.Export.NotFound' -StringValues $idOrName, $resourceName, $tenant.displayName 
                }
            }#>
        } else {
            foreach ($g in (Get-AllGroups -Scope $Scope)) {
                $groupsExport += Convert-Group $g $PAGs
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
