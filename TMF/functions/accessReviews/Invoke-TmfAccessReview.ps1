function Invoke-TmfAccessReview {
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
		$resourceName = "accessReviews"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "accessReview"
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
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessReview" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
			if ($SpecificResources) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessReview" -String "TMF.Invoke.Confirmed" -StringValues "accessReview configuration for resources: $($SpecificResources -join ",")"
				$testResults = Test-TmfAccessReview -specificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceFile) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessReview" -String "TMF.Invoke.Confirmed" -StringValues "accessReview configuration for SourceFile(s): $($SourceFile -join ",")"
				$testResults = Test-TmfAccessReview -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceConfig) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessReview" -String "TMF.Invoke.Confirmed" -StringValues "accessReview configuration for SourceConfig(s): $($SourceConfig -join ",")"
				$testResults = Test-TmfAccessReview -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
			}
			else {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessReview" -String "TMF.Invoke.Confirmed" -StringValues "all accessReview configurations"
				$testResults = Test-TmfAccessReview -RawOutput -Cmdlet $Cmdlet
			}	
		}
		else {
			if ($SpecificResources) {
				$testResults = Test-TmfAccessReview -specificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceFile) {
				$testResults = Test-TmfAccessReview -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceConfig) {
				$testResults = Test-TmfAccessReview -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
			}
			else {
				$testResults = Test-TmfAccessReview -RawOutput -Cmdlet $Cmdlet
			}
		}

        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl/identityGovernance/accessReviews/definitions"
					$requestMethod = "POST"
					if ($result.DesiredConfiguration.scope.query -match "transitiveMembers/microsoft.graph.user") {
						$result.DesiredConfiguration.scope.query = $result.DesiredConfiguration.scope.query -replace "/microsoft.graph.user", ""
					}
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"scope" = $result.DesiredConfiguration.scope
						"reviewers" = $result.DesiredConfiguration.reviewers
						"fallbackReviewers" = $result.DesiredConfiguration.fallbackReviewers
                        "settings" = $result.DesiredConfiguration.settings
					}
                    try {
						$requestBody = $requestBody | ConvertTo-Json -Depth 4
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
                }
                "Delete" {
                    $requestUrl = "$script:graphBaseUrl/identityGovernance/accessReviews/definitions/{0}" -f $result.GraphResource.Id
					$requestMethod = "DELETE"
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
                }
                "Update" {
                    $requestUrl = "$script:graphBaseUrl/identityGovernance/accessReviews/definitions/{0}" -f $result.GraphResource.Id
					$requestMethod = "PUT"
					$requestBody = @{
                        "id" = $result.GraphResource.Id						
						"displayName" = $result.DesiredConfiguration.displayName
						"scope" = $result.DesiredConfiguration.scope
						"reviewers" = $result.DesiredConfiguration.reviewers
						"fallbackReviewers" = $result.DesiredConfiguration.fallbackReviewers
                        "settings" = $result.DesiredConfiguration.settings
					}
                    $requestBody = $requestBody | ConvertTo-Json -Depth 4
                    try {
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
                    Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
                }
            }
            Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
        }
    }
    end {}
}