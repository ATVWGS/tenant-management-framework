function Export-TmfAuthorizationPolicy {
    <#
    .SYNOPSIS
    Retrieves the singleton authorizationPolicy (v1.0 by default; beta when -ForceBeta or v1.0 unsupported) and converts it to the TMF shape. Returns object unless -OutPath is supplied.
    .PARAMETER SpecificResources
    Optional filter by display name (wildcards). Singleton; typically omitted.
    .PARAMETER OutPath
    Root folder to write export; when omitted the object is returned.
    .PARAMETER ForceBeta
    Always use beta endpoint (or fallback when v1.0 fails/insufficient).
    .PARAMETER Cmdlet
    Internal pipeline parameter; do not supply manually.
    .EXAMPLE
    Export-TmfAuthorizationPolicy -OutPath C:\tmf
    .EXAMPLE
    Export-TmfAuthorizationPolicy | ConvertTo-Json -Depth 15
    #>

    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [Alias('OutPutPath')] [string] $OutPath,
        #Register, Test and Invoke function use beta endpoint. Has to be adjusted to v1.0 first before ForceBeta = $true can be removed
        [switch] $ForceBeta = $true,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )

    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'authorizationPolicies'
        $parentName = 'policies'
        function Convert-AuthorizationPolicy { 
            param([object]$policy) 
            $o = [PSCustomObject][ordered]@{
                present = $true
            }
            if ($policy.displayName) { 
                Add-Member -InputObject $o -MemberType NoteProperty -Name "displayName" -Value $policy.displayName 
            }
            foreach ($p in 'allowInvitesFrom','allowedToSignUpEmailBasedSubscriptions','allowedToUseSSPR','allowEmailVerifiedUsersToJoinOrganization','blockMsolPowerShell','guestUserRoleId','allowedToCreateApps','allowedToCreateSecurityGroups','allowedToReadOtherUsers','allowedToReadBitlockerKeysForOwnedDevice','permissionGrantPolicyIdsAssignedToDefaultUserRole') { 
                if ($policy.PSObject.Members.Match($p) -and $null -ne $policy.$p) { 
                    if ($p -eq "guestUserRoleId") {
                        switch ($policy.$p) {
                            "a0b1b346-4d3e-4e8b-98f8-753987be4970" {Add-Member -InputObject $o -MemberType NoteProperty -Name "guestUserRole" -Value "User"}
                            "10dae51f-b6af-4016-8d66-8c2a99b929b3" {Add-Member -InputObject $o -MemberType NoteProperty -Name "guestUserRole" -Value "Guest User"}
                            "2af84b1e-32c8-42b7-82bc-daa82404023b" {Add-Member -InputObject $o -MemberType NoteProperty -Name "guestUserRole" -Value "Restricted Guest User"}
                        }
                    }
                    else {
                        Add-Member -InputObject $o -MemberType NoteProperty -Name $p -Value $policy.$p
                    }                    
                } 
            } 
            if ($policy.defaultUserRolePermissions) { 
                $durp = $policy.defaultUserRolePermissions
                foreach ($prop in $durp.getEnumerator()) { 
                    if ($prop.Name -ne '@odata.type' -and $null -ne $prop.Value) { 
                        Add-Member -InputObject $o -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
                    } 
                } 
            }
            [pscustomobject]$o 
        }
    }
    process {
        $policy = $null; $usedBeta = $false
        if (-not $ForceBeta) {
            try {
                $policy = Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl1/policies/authorizationPolicy"
            } catch {
                Write-PSFMessage -Level Verbose -Message ('v1.0 retrieval failed: {0}' -f $_.Exception.Message)
            }
        }
        if ($ForceBeta -or -not $policy) {
            try {
                $policy = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrlbeta/policies/authorizationPolicy").value; $usedBeta = $true
            } catch {
                Write-PSFMessage -Level Verbose -Message ('beta retrieval failed: {0}' -f $_.Exception.Message)
            }
        }
        if (-not $policy) {
            if (-not $OutPutPath) {
                return @()
            } else {
                return
            }
        }
        $exportObject = Convert-AuthorizationPolicy $policy
        if ($SpecificResources) {
            $filters = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ }; if (($filters | Where-Object { $exportObject.displayName -like $_ }).Count -eq 0 -and ($filters -notcontains '*')) {
                if (-not $OutPutPath) {
                    return @()
                } else {
                    return
                }
            }
        }
        Write-PSFMessage -Level Verbose -FunctionName 'Export-TmfAuthorizationPolicy' -Message ("Exporting authorization policy. ForceBeta={0} UsedBeta={1}" -f $ForceBeta, $usedBeta)
    }
    end {
        if (-not $OutPath) {
            return @($exportObject)
        }
        if ($exportObject) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath $parentName -ResourceName $resourceName -Data @($exportObject)
        }        
    }
}
