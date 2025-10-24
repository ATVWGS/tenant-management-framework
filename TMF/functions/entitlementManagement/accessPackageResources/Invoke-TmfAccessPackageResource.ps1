function Invoke-TmfAccessPackageResource {
	<#
		.SYNOPSIS
			Performs the required actions for a resource type against the connected Tenant.
	#>
	[CmdletBinding()]
	param (
		[string[]] $SpecificResources,
		[string[]] $SourceFile,
		[string[]] $SourceConfig,
		[switch] $Confirm = $false,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

	begin {
		$resourceName = "accessPackageResources"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "AccessPackageResource"
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
	process {
		if (Test-PSFFunctionInterrupt) {
			return 
  }
		if (-not $Confirm) {
			Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessPackageResource" -String "TMF.TenantInformation" -StringValues $tenant.displayName, $tenant.Id
			if ((Read-Host "Is this the correct tenant? [y/n]") -notin @("y", "Y"))	{
				Write-PSFMessage -Level Error -String "TMF.UserCanceled"
				throw "Connected to the wrong tenant."
			}
			if ($SpecificResources) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessPackageResource" -String "TMF.Invoke.Confirmed" -StringValues "accessPackageResource configuration for resources: $($SpecificResources -join ",")"
				$testResults = Test-TmfAccessPackageResource -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
			} elseif ($SourceFile) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessPackageResource" -String "TMF.Invoke.Confirmed" -StringValues "accessPackageResource configuration for SourceFile(s): $($SourceFile -join ",")"
				$testResults = Test-TmfAccessPackageResource -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
			} elseif ($SourceConfig) {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessPackageResource" -String "TMF.Invoke.Confirmed" -StringValues "accessPackageResource configuration for SourceConfig(s): $($SourceConfig -join ",")"
				$testResults = Test-TmfAccessPackageResource -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
			} else {
				Write-PSFMessage -Level Host -FunctionName "Invoke-TmfAccessPackageResource" -String "TMF.Invoke.Confirmed" -StringValues "all accessPackageResource configurations"
				$testResults = Test-TmfAccessPackageResource -RawOutput -Cmdlet $Cmdlet
			}
		} else {
			if ($SpecificResources) {
				$testResults = Test-TmfAccessPackageResource -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
			} elseif ($SourceFile) {
				$testResults = Test-TmfAccessPackageResource -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
			} elseif ($SourceConfig) {
				$testResults = Test-TmfAccessPackageResource -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
			} else {
				$testResults = Test-TmfAccessPackageResource -RawOutput -Cmdlet $Cmdlet
			}
		}

		foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
			switch ($result.ActionType) {
				"Create" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageResourceRequests"
					$requestMethod = "POST"

					$requestBody = @{
						"accessPackageResource" = @{
							"displayName"  = $result.DesiredConfiguration.displayName
							"description"  = $result.DesiredConfiguration.description
							"resourceType" = $result.DesiredConfiguration.resourceType
							"originSystem" = $result.DesiredConfiguration.originSystem
							"originId"     = $result.DesiredConfiguration.originId()
						}
						"justification"         = "Resource is required for an Access Package managed by the Tenant Managment Framework"
						"requestType"           = "AdminAdd"
						"catalogId"             = $result.DesiredConfiguration.catalogId()
					}
					try {
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
					} catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"Delete" {
					$requestUrl = "$script:graphBaseUrl/identityGovernance/entitlementManagement/accessPackageResourceRequests"
					$requestMethod = "POST"

					$requestBody = @{
						"accessPackageResource" = @{
							"displayName"  = $result.DesiredConfiguration.displayName
							"description"  = $result.DesiredConfiguration.description
							"resourceType" = $result.DesiredConfiguration.resourceType
							"originSystem" = $result.DesiredConfiguration.originSystem
							"originId"     = $result.DesiredConfiguration.originId()
						}
						"justification"         = "Resource is not longer required for an Access Package managed by the Tenant Managment Framework"
						"requestType"           = "AdminRemove"
						"catalogId"             = $result.DesiredConfiguration.catalogId()
					}
					try {
						$requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop -Depth 8
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
					} catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
				}
				"NoActionRequired" { 
    }
				default {
					Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.ActionType
				}
			}
			Write-PSFMessage -Level Host -String "TMF.Invoke.ActionCompleted" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType
		}
	}
	end {
		Import-TmfConfiguration -Cmdlet $Cmdlet
	}
}
