function Invoke-TmfCustomAuthenticationExtension {
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
		$resourceName = "customAuthenticationExtensions"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "customAuthenticationExtensions"
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
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomAuthenticationExtension" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y","Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
			if ($SpecificResources) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomAuthenticationExtension" -String "TMF.Invoke.Confirmed" -StringValues "customAuthenticationExtension configuration for resources: $($SpecificResources -join ",")"
				$testResults = Test-TmfCustomAuthenticationExtension -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceFile) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomAuthenticationExtension" -String "TMF.Invoke.Confirmed" -StringValues "customAuthenticationExtension configuration for SourceFile(s): $($SourceFile -join ",")"
				$testResults = Test-TmfCustomAuthenticationExtension -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceConfig) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomAuthenticationExtension" -String "TMF.Invoke.Confirmed" -StringValues "customAuthenticationExtension configuration for SourceConfig(s): $($SourceConfig -join ",")"
				$testResults = Test-TmfCustomAuthenticationExtension -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
			}
			else {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfCustomAuthenticationExtension" -String "TMF.Invoke.Confirmed" -StringValues "all customAuthenticationExtension configurations"
				$testResults = Test-TmfCustomAuthenticationExtension -RawOutput -Cmdlet $Cmdlet
			}
		}
		else {
			if ($SpecificResources) {
				$testResults = Test-TmfCustomAuthenticationExtension -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceFile) {
				$testResults = Test-TmfCustomAuthenticationExtension -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
			}
			elseif ($SourceConfig) {
				$testResults = Test-TmfCustomAuthenticationExtension -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
			}
			else {
				$testResults = Test-TmfCustomAuthenticationExtension -RawOutput -Cmdlet $Cmdlet
			}
		}
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl1/identity/customAuthenticationExtensions"
					$requestMethod = "POST"
					$requestBody = @{						
						"displayName" = $result.DesiredConfiguration.displayName
						"description" = $result.DesiredConfiguration.description
                        "@odata.type" = $result.DesiredConfiguration."@odata.type"
						"authenticationConfiguration" = $result.DesiredConfiguration.authenticationConfiguration
						"endpointConfiguration" = $result.DesiredConfiguration.endpointConfiguration
					}
					if ($result.DesiredConfiguration.properties() -contains "clientConfiguration") {
						$requestBody["clientConfiguration"] = $result.DesiredConfiguration.clientConfiguration
					}
					if ($result.DesiredConfiguration.properties() -contains "claimsForTokenConfiguration") {
						$requestBody["claimsForTokenConfiguration"] = $result.DesiredConfiguration.claimsForTokenConfiguration
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
                "Update" {
                    $requestUrl = "$script:graphBaseUrl1/identity/customAuthenticationExtensions/{0}" -f $result.GraphResource.Id
                    $requestMethod = "PATCH"
                    $requestBody = @{}
					try {
						foreach ($change in $result.Changes) {
							foreach ($action in $change.Actions.Keys) {
								switch ($action) {
									"Set" {										
										$requestBody[$change.property] = $change.Actions[$action]
									}									
								}
							}
						}
						$requestBody["@odata.type"] = $result.DesiredConfiguration."@odata.type"
						if ($requestBody.Keys -gt 0) {
							$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
							Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
							Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
						}
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
                }
                "Delete" {
                    $requestUrl = "$script:graphBaseUrl1/identity/customAuthenticationExtensions/{0}" -f $result.GraphResource.Id
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