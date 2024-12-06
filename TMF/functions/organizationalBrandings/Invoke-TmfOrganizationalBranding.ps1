function Invoke-TmfOrganizationalBranding
{
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "organizationalBranding"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "organizationalBrandings"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}

    process
    {
        if(Test-PSFFunctionInterrupt) {return}
		$testResults = Test-TmfOrganizationalBranding -Cmdlet $Cmdlet


        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                    $requestUrl = "$script:graphBaseUrl1/organization/$($result.TenantId)/branding/localizations"
                    $requestMethod = "POST"
                    $requestBody  = @{
                        "id" = $result.DesiredConfiguration.displayName
                    }
                    $result.DesiredConfiguration.properties() | Where-Object {$_ -notin @("displayname","present","sourceConfig")} | ForEach-Object {
                        $requestBody[$_] = $result.DesiredConfiguration.$_
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
                "Delete" {
                    if ($result.DesiredConfiguration.displayName -eq "default") {
                        Write-PSFMessage -Level Warning -String 'TMF.Test.DeleteNotPossible' -StringValues $resourceName, $definition.displayName
                    }
                    else {
                        $requestUrl = "$script:graphBaseUrl1/organization/$($result.TenantId)/branding/localizations/{0}" -f $result.GraphResource.Id
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
                }
                "Update" {

                    $requestUrl = "$script:graphBaseUrl1/organization/$($result.TenantId)/branding/localizations/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
                    foreach ($change in $result.Changes) {
                        foreach ($action in $change.Actions.Keys){
                            switch ($action) {
                                "Set" {
                                    $requestBody[$change.Property] = $change.Actions[$action]
                                }
                            }
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
    end
	{
	}
}