function Invoke-TmfAuthorizationPolicy {
    <#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
        [string[]] $SpecificResources,
        [string[]] $SourceFile,
		[string[]] $SourceConfig,
        [switch] $Confirm = $false,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "authorizationPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "authorizationPolicies"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value

        if (($SpecificResources -and $SourceFile -and $SourceConfig) -or ($SpecificResources -and $SourceFile) -or ($SourceFile -and $SourceConfig)) {
			$exception = New-Object System.Data.DataException("Multiple filters are not supported. You can only filter by one type, sourceFile or sourceConfig or specificResources!")
			$errorID = "MultipleFiltersNotSupported"
			$category = [System.Management.Automation.ErrorCategory]::NotSpecified
			$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
			$cmdlet.ThrowTerminatingError($recordObject)
		}
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
        if (-not $Confirm) {
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthorizationPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
            if ($SpecificResources) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthorizationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "authorizationPolicy configuration for resources: $($SpecificResources -join ",")"
                $testResults = Test-TmfAuthorizationPolicy -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceFile) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthorizationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "authorizationPolicy configuration for SourceFile(s): $($SourceFile -join ",")"
                $testResults = Test-TmfAuthorizationPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthorizationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "authorizationPolicy configuration for SourceConfig(s): $($SourceConfig -join ",")"
                $testResults = Test-TmfAuthorizationPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthorizationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "all authorizationPolicy configurations"
                $testResults = Test-TmfAuthorizationPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
        else {
            if ($SpecificResources) {
                $testResults = Test-TmfAuthorizationPolicy -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceFile) {
                $testResults = Test-TmfAuthorizationPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                $testResults = Test-TmfAuthorizationPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                $testResults = Test-TmfAuthorizationPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $requestMethod = "PATCH"
                    $requestUrl = "$script:graphBaseUrl/policies/authorizationPolicy/authorizationPolicy"
                    $requestBody = @{
                        "allowInvitesFrom" = $result.DesiredConfiguration.allowInvitesFrom
                        "allowedToSignUpEmailBasedSubscriptions" =  $result.DesiredConfiguration.allowedToSignUpEmailBasedSubscriptions
                        "allowedToUseSSPR" = $result.DesiredConfiguration.allowedToUseSSPR
                        "allowedEmailVerifiedUsersToJoinOrganization" = $result.DesiredConfiguration.allowedEmailVerifiedUsersToJoinOrganization
                        "blockMsolPowerShell" =  $result.DesiredConfiguration.blockMsolPowerShell
                        "guestUserRoleId" = $result.DesiredConfiguration.guestUserRoleId
                        "permissionGrantPolicyIdsAssignedToDefaultUserRole" = $result.DesiredConfiguration.permissionGrantPolicyIdsAssignedToDefaultUserRole
                        "defaultUserRolePermissions" = $result.DesiredConfiguration.defaultUserRolePermissions
                    }
                    $requestBody = $requestBody | ConvertTo-Json -Depth 5

                    try {
                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                        Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                        Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                    }
                    catch {
                        Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                        throw $_
                    }
                }
                "NoActionRequired" {}
            }
        }
    }

    end {}
}