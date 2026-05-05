function Invoke-TmfAdminConsentRequestPolicy {
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
		$resourceName = "adminConsentRequestPolicy"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "adminConsentRequestPolicy"
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
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAdminConsentRequestPolicy" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
            if ($SourceFile) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAdminConsentRequestPolicy" -String "TMF.Invoke.Confirmed" -StringValues "adminConsentRequestPolicy configuration for SourceFile(s): $($SourceFile -join ",")"
                $testResults = Test-TmfAdminConsentRequestPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAdminConsentRequestPolicy" -String "TMF.Invoke.Confirmed" -StringValues "adminConsentRequestPolicy configuration for SourceConfig(s): $($SourceConfig -join ",")"
                $testResults = Test-TmfAdminConsentRequestPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAdminConsentRequestPolicy" -String "TMF.Invoke.Confirmed" -StringValues "all adminConsentRequestPolicy configurations"
                $testResults = Test-TmfAdminConsentRequestPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
        else {
            if ($SourceFile) {
                $testResults = Test-TmfAdminConsentRequestPolicy -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
            }
            elseif ($SourceConfig) {
                $testResults = Test-TmfAdminConsentRequestPolicy -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
            }
            else {
                $testResults = Test-TmfAdminConsentRequestPolicy -RawOutput -Cmdlet $Cmdlet
            }
        }
        		
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Update" {
                    $requestUrl = "$script:graphBaseUrl/policies/adminConsentRequestPolicy"
                    $requestMethod = "PUT"
                    $requestBody = @{						
                        "isEnabled" = $result.DesiredConfiguration.isEnabled
                        "notifyReviewers" = $result.DesiredConfiguration.notifyReviewers
                        "remindersEnabled" = $result.DesiredConfiguration.remindersEnabled
                        "requestDurationInDays" = $result.DesiredConfiguration.requestDurationInDays
                        "reviewers" = $result.DesiredConfiguration.reviewers
                    }
                    try {						
                        $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                        $policy = Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
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