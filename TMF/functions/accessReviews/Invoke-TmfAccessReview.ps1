function Invoke-TmfAccessReview {
    <#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	Param (
		[string[]] $SpecificResources,
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
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
		if ($SpecificResources) {
        	$testResults = Test-TmfAccessReview -specificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfAccessReview -Cmdlet $Cmdlet
		}

        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl/identityGovernance/accessReviews/definitions"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"scope" = $result.DesiredConfiguration.scope
						"reviewers" = $result.DesiredConfiguration.reviewers
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