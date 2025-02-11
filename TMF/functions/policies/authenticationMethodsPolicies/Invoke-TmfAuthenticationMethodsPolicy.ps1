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