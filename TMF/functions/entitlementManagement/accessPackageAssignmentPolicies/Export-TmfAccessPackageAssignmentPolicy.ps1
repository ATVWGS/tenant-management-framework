function Export-TmfAccessPackageAssignmentPolicy {
    [CmdletBinding()] Param(
        [string[]]$SpecificResources,
        [string]$OutPutPath,
        [System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
    )
    begin {        
        Test-GraphConnection -Cmdlet $Cmdlet
        $resourceName = 'accessPackageAssignmentPolicies'
        $base = ($script:graphBaseUrl -replace '/beta$','/v1.0')
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$base/organization?`$select=displayName,id")).value
        $export = @()
        function Simplify-SubjectSets { param($sets) if(-not $sets){ return @() }; return ($sets | ForEach-Object { if($_.additionalProperties){ $_.additionalProperties } else { $_ } }) }
        function Convert-Policy { param($p) [ordered]@{ displayName=$p.displayName; accessPackage=$p.accessPackage.displayName; allowedTargetScope=$p.allowedTargetScope; specificAllowedTargets=(Simplify-SubjectSets $p.specificAllowedTargets); expiration=$p.expiration; reviewSettings=$p.reviewSettings; requestApprovalSettings=$p.requestApprovalSettings; requestorSettings=$p.requestorSettings; automaticRequestSettings=$p.automaticRequestSettings; present=$true } }
        function Get-AllPolicies {
            $list=@(); $expand='accessPackage';
            try { $resp = Invoke-MgGraphRequest -Method GET -Uri "$base/identityGovernance/entitlementManagement/assignmentPolicies?`$top=50&`$expand=$expand" -ErrorAction Stop } catch { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageAssignmentPolicy' -Message $_.Exception.Message; return $list }
            if ($resp.'@odata.nextLink'){ do { $list += $resp.value; $resp = Invoke-MgGraphRequest -Method GET -Uri $resp.'@odata.nextLink' } while ($resp.'@odata.nextLink') } else { $list += $resp.value }
            return $list
        }
        $all = Get-AllPolicies
    }
    process {
        if ($SpecificResources){
            $ids = $SpecificResources | ForEach-Object { $_ -split ',' } | ForEach-Object Trim | Where-Object { $_ } | Select-Object -Unique
            foreach($id in $ids){ $match = $all | Where-Object displayName -eq $id; if($match){ $match | ForEach-Object { $export += Convert-Policy $_ } } else { Write-PSFMessage -Level Warning -FunctionName 'Export-TmfAccessPackageAssignmentPolicy' -String 'TMF.Export.NotFound' -StringValues $id,$resourceName,$tenant.displayName } }
        } else { foreach($p in $all){ $export += Convert-Policy $p } }
    }
    end {
        $emRoot = Join-Path $OutPutPath 'entitlementManagement'
        if(-not (Test-Path $emRoot)){ New-Item -Path $OutPutPath -Name 'entitlementManagement' -ItemType Directory -Force | Out-Null }
        $path = Join-Path $emRoot $resourceName; if(-not(Test-Path $path)){ New-Item -Path $emRoot -Name $resourceName -ItemType Directory -Force | Out-Null }
        $export | ConvertTo-Json -Depth 25 | Out-File -FilePath (Join-Path $path "$resourceName.json") -Encoding utf8 -Force
    }
}
