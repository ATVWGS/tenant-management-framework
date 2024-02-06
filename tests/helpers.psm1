function Get-GraphAccessToken {
    Param (
        [Parameter(Mandatory = $true)]
        $TenantId,
        [Parameter(Mandatory = $true)]
        $TenantClientSecret,
        [Parameter(Mandatory = $true)]
        $TenantClientId
    )

    begin {
        $body = @{    
            grant_type    = "client_credentials"
            scope         = "https://graph.microsoft.com/.default"
            client_id     = $TenantClientId
            client_secret = $TenantClientSecret
        }
    }
    process {
        $request = Invoke-RestMethod -Method POST -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body
    }
    end {
        return $request.access_token
    }
}

function Get-Definitions {
    Param (
        [Parameter(Mandatory = $true)]
        $DataFilePath
    )
    begin {
        $timestamp = Get-Date -UFormat "%Y%m%d"
        $definitions = Import-PowerShellDataFile -Path $DataFilePath
    }
    process {
        $definitions.GetEnumerator() | Foreach-Object {
            $_.Value | Foreach-Object {
                if ($_["displayName"]) {
                    $_["displayName"] = $_["displayName"] -replace "{{ timestamp }}", $timestamp
                }
            }
        }
    }
    end {
        return $definitions
    }
}

Export-ModuleMember -Function "Get-GraphAccessToken", "Get-Definitions" -Variable "uris"