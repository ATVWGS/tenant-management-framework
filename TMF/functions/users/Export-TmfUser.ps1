function Export-TmfUser {
    <#
    .SYNOPSIS
    Exports Azure AD users into TMF configuration objects or JSON.
    .DESCRIPTION
    Retrieves users via Microsoft Graph (v1.0 by default; beta when -ForceBeta) and converts them to the TMF shape. Returns objects unless -OutPath is supplied, in which case JSON is written to users/users.json.
    .PARAMETER SpecificResources
    Optional list of userPrincipalNames or IDs (comma separated accepted) to filter.
    .PARAMETER OutPath
    Root folder to write the export. When omitted, objects are returned instead of writing files.
    .PARAMETER ForceBeta
    Use beta Graph endpoint for retrieval (may expose additional properties).
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .NOTES
    Backward compatibility: legacy alias -OutPutPath is still accepted but deprecated (will emit one warning per session when used).
    .EXAMPLE
    Export-TmfUser -OutPath C:\temp\tmf
    .EXAMPLE
    Export-TmfUser -SpecificResources alice@contoso.com,bob@contoso.com | ConvertTo-Json -Depth 15
    #>

    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        [switch] $ForceBeta,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'users'
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayname,id")).value
        $usersExport = @()
        $select = 'id,displayName,userPrincipalName,mail,mailNickname,accountEnabled,givenName,surname,userType'
        function Convert-User {
            param([object]$u) [ordered]@{ displayName = $u.displayName; userPrincipalName = $u.userPrincipalName; mail = $u.mail; mailNickname = $u.mailNickname; accountEnabled = $u.accountEnabled; givenName = $u.givenName; surname = $u.surname; userType = $u.userType; present = $true }
        }
        function Get-AllUsers {
            $list = @()
            $uri = "$(if ($ForceBeta) { $script:graphBaseUrlbeta } else { $script:graphBaseUrl1 })/users?`$top=999&`$select=$select"
            while ($uri) {
                $resp = Invoke-MgGraphRequest -Method GET -Uri $uri
                if ($resp.value) {
                    $list += $resp.value
                }
                $uri = $resp.'@odata.nextLink'
            }
            return $list
        }
    }
    process {
        if ($SpecificResources) {
            $identifiers = @(); foreach ($entry in $SpecificResources) {
                $identifiers += $entry -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }; $identifiers = $identifiers | Select-Object -Unique
            $allUsers = Get-AllUsers
            foreach ($idOrUpn in $identifiers) {
                $match = $allUsers | Where-Object { $_.id -eq $idOrUpn -or $_.userPrincipalName -eq $idOrUpn }
                if ($match) {
                    foreach ($m in $match) {
                        $usersExport += Convert-User $m
                    }
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfUser' -String 'TMF.Export.NotFound' -StringValues $idOrUpn, $resourceName, $tenant.displayName
                }
            }
        } else {
            foreach ($u in (Get-AllUsers)) {
                $usersExport += Convert-User $u
            }
        }
    }
    end {
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfUser' -Message "Exporting $($usersExport.Count) user(s). ForceBeta=$ForceBeta"
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -InvocationLine $MyInvocation.Line -LegacyParameter 'OutPutPath' -NewParameter 'OutPath'
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ResourceName $resourceName -Data $usersExport
        } else {
            return $usersExport
        }
    }
}
