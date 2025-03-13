function Invoke-TmfAuthenticationMethodsPolicy {
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
		$resourceName = "authenticationMethodsPolicies"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "authenticationMethodsPolicies"
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
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationMethodsPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
            if ($SpecificResources) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationMethodsPolicy" -String "TMF.Invoke.Confirmed" -StringValues "authenticationMethodsPolicy configuration for resources: $($SpecificResources -join ",")"
                $testResults = Test-TmfAuthenticationMethodsPolicy -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceFile) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationMethodsPolicy" -String "TMF.Invoke.Confirmed" -StringValues "authenticationMethodsPolicy configuration for SourceFile(s): $($SourceFile -join ",")"
                $testResults = Test-TmfAuthenticationMethodsPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationMethodsPolicy" -String "TMF.Invoke.Confirmed" -StringValues "authenticationMethodsPolicy configuration for SourceConfig(s): $($SourceConfig -join ",")"
                $testResults = Test-TmfAuthenticationMethodsPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAuthenticationMethodsPolicy" -String "TMF.Invoke.Confirmed" -StringValues "all authenticationMethodsPolicy configurations"
                $testResults = Test-TmfAuthenticationMethodsPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
        else {
            if ($SpecificResources) {
                $testResults = Test-TmfAuthenticationMethodsPolicy -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceFile) {
                $testResults = Test-TmfAuthenticationMethodsPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                $testResults = Test-TmfAuthenticationMethodsPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                $testResults = Test-TmfAuthenticationMethodsPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $result.changes | ForEach-Object {
                        $change = $_
                        switch ($change.Property) {
                            "registrationEnforcement" {
                                $requestMethod = "PATCH"
                                $requestUrl = "$script:graphBaseUrl/policies/authenticationMethodsPolicy"
                                $requestBody = @{
                                    "registrationEnforcement" = $result.DesiredConfiguration.registrationEnforcement
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
                            "authenticationMethodConfigurations" {
                                foreach ($id in $change.actions.values) {
                                    $id
                                    $requestMethod = "PATCH"
                                    $requestUrl = "$script:graphBaseUrl/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/$($id)"
                                    $requestBody = $result.DesiredConfiguration.authenticationMethodConfigurations | Where-Object {$_.id -eq $id}
                                    Add-Member -InputObject $requestBody -MemberType NoteProperty -Name "@odata.type" -Value "#microsoft.graph.$($id.tolower())AuthenticationMethodConfiguration"
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
                            }
                        }
                    }
                }
                "NoActionRequired" {}
            }
        }
    }

    end {}
}