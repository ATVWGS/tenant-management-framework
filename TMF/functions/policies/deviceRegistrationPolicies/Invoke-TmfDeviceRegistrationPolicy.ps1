function Invoke-TmfDeviceRegistrationPolicy {
    <#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
        [string[]] $SourceFile,
		[string[]] $SourceConfig,
        [switch] $Confirm = $false,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "deviceRegistrationPolicy"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "deviceRegistrationPolicy"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/organization?`$select=displayname,id")).value

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
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfDeviceRegistrationPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
            if ($SourceFile) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfDeviceRegistrationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "deviceRegistrationPolicy configuration for SourceFile(s): $($SourceFile -join ",")"
                $testResults = Test-TmfDeviceRegistrationPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfDeviceRegistrationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "deviceRegistrationPolicy configuration for SourceConfig(s): $($SourceConfig -join ",")"
                $testResults = Test-TmfDeviceRegistrationPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfDeviceRegistrationPolicy" -String "TMF.Invoke.Confirmed" -StringValues "all deviceRegistrationPolicy configurations"
                $testResults = Test-TmfDeviceRegistrationPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
        else {
            if ($SourceFile) {
                $testResults = Test-TmfDeviceRegistrationPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                $testResults = Test-TmfDeviceRegistrationPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                $testResults = Test-TmfDeviceRegistrationPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
        		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $requestUrl = "$script:graphBaseUrl1/policies/deviceRegistrationPolicy"
                    $requestMethod = "PUT"
                    $requestBody = @{						
                        "userDeviceQuota" = $result.DesiredConfiguration.userDeviceQuota
                        "multiFactorAuthConfiguration" = $result.DesiredConfiguration.multiFactorAuthConfiguration
                        "azureADRegistration" = $result.DesiredConfiguration.azureADRegistration
                        "azureADJoin" = $result.DesiredConfiguration.azureADJoin
                        "localAdminPassword" = $result.DesiredConfiguration.localAdminPassword
                    }
                    try {						
                        $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                        Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                    }
                    catch {
                        Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                        throw $_
                    }
                }
                "NoActionRequired" {}
                default {
					Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.ActionType
				}
            }
            Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
        }
    }

    end {}
}