function Invoke-TmfDirectorySetting {
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
		$resourceName = "DirectorySettings"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "directorySetting"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}
	process
	{
        if(Test-PSFFunctionInterrupt) {return}
		if ($SpecificResources) {
        	$testResults = Test-TmfDirectorySetting -SpecificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfDirectorySetting -Cmdlet $Cmdlet
		}

        foreach ($result in $testResults) {
			Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {

					$requestUrl = "$script:graphBaseUrl/settings"
                    $requestMethod = "POST"
                    $requestBody  = @{
                        "templateId" = $result.DesiredConfiguration.templateId
                    }
					$requestBody["values"] = @()
                    $result.DesiredConfiguration.properties() | Where-Object {$_ -notin @("displayname","present","sourceConfig","templateId")} | ForEach-Object {
                        $requestBody["values"] += @{
							"name" = $_
							"value" = [string]$result.DesiredConfiguration.$_
						}
                    }

                    $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
					$requestBody
                    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                    try {
                        Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                    }
                    catch {
                        Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                        throw $_
                    }					
                }
                "Delete" {
					$requestUrl = "$script:graphBaseUrl/settings/{0}" -f $result.GraphResource.Id
					$requestMethod = "DELETE"

					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl | Out-Null
					}
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
						throw $_
					}
                }
				"Update" {
					$requestUrl = "$script:graphBaseUrl/settings/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
					$requestBody["values"] = @()
                    $result.DesiredConfiguration.properties() | Where-Object {$_ -notin @("displayname","present","sourceConfig","templateId")} | ForEach-Object {
                        $requestBody["values"] += @{
							"name" = $_
							"value" = [string]$result.DesiredConfiguration.$_
						}
                    }

                    $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
                    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                    try {
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
}