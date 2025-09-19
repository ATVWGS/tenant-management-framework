function Export-TmfAccessPackageAssignmentPolicy {
    [CmdletBinding()] param(
        [string[]]$SpecificResources,
        [Alias('OutPutPath')] [string]$OutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessPackageAssignmentPolicies'
        $base = ($script:graphBaseUrl -replace '/beta$', '/v1.0')
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$($script:graphBaseUrl)/organization?`$select=displayName,id")).value
        $export = @()
        function Simplify-SubjectSets {
            param($sets) if (-not $sets) {
                return @() 
            }; return ($sets | ForEach-Object { if ($_.additionalProperties) {
                        $_.additionalProperties 
                    } else {
                        $_ 
                    } }) 
        }
        function Convert-Policy {
            param($p) [ordered]@{ displayName = $p.displayName; accessPackage = $p.accessPackage.displayName; allowedTargetScope = $p.allowedTargetScope; specificAllowedTargets = (Simplify-SubjectSets $p.specificAllowedTargets); expiration = $p.expiration; reviewSettings = $p.reviewSettings; requestApprovalSettings = $p.requestApprovalSettings; requestorSettings = $p.requestorSettings; automaticRequestSettings = $p.automaticRequestSettings; present = $true } 
        }
        function Get-AllPolicies {
            $list = @(); $expand = 'accessPackage'
            try {
                $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/assignmentPolicies?`$top=50&`$expand=$expand" -ErrorAction Stop 
            } catch {
                Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageAssignmentPolicy' -Message $_.Exception.Message; return $list 
            }
            if ($resp.'@odata.nextLink') {
                do {
                    $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' 
                } while ($resp.'@odata.nextLink') 
            } else {
                $list += $resp.value 
            }
            return $list
        }
        $all = Get-AllPolicies
    }
    process {
        if ($SpecificResources) {
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique
            foreach ($id in $ids) {
                $match = $all | Where-Object displayName -EQ $id; if ($match) {
                    $match | ForEach-Object { $export += Convert-Policy $_ } 
                } else {
                    Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageAssignmentPolicy' -String 'TMF.Export.NotFound' -StringValues $id, $resourceName, $tenant.displayName 
                } 
            }
        } else {
            foreach ($p in $all) {
                $export += Convert-Policy $p 
            } 
        }
    }
    end {
        if ($PSBoundParameters.ContainsKey('OutPutPath')) {
            Write-TmfDeprecatedParameterWarning -Cmdlet $Cmdlet -LegacyName 'OutPutPath' -NewName 'OutPath' 
        }
        if ($OutPath) {
            Write-TmfExportFile -OutPath $OutPath -ParentPath 'entitlementManagement' -ResourceName $resourceName -Data $export
        } else {
            return $export 
        }
    }
}
