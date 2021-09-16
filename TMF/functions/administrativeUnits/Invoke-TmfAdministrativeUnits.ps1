function Invoke-TmfAdministrativeUnits
{
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
		
	
	begin
	{
		$resourceName = "administrativeUnits";
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "administrativeUnits";
			return;
		}
		Test-GraphConnection -Cmdlet $Cmdlet;
	}

    process
    {
        if(Test-PSFFunctionInterrupt) {return}
        $testResults = Test-TmfAdministrativeUnits -Cmdlet $Cmdlet;

        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName MyInvocation.MyCommand;
            switch ($result.ActionType) {
## Create Sektion: Creation of the Administrative Unit
                "Create" {
                    $requestUrl    = "$script:graphBaseUrl/administrativeUnits";
                    $requestMethod = "POST";
                    $requestBody   = @{
                        "displayName" = $result.DesiredConfiguration.displayName
                        "description" = $result.DesiredConfiguration.description
                        "visibility"  = $result.DesiredConfiguration.visibilty
                        }
                    $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop;
                    Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody;
                    Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null;
                    }
                 catch {
				    Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType;
					throw $_;
					}
## Delete Sektion: Deletion of the Administrative Unit
                "Delete" {
                    $requestUrl     = "$script:graphBaseUrl/administrativeUnits/{0}" -f $result.GraphResource.Id;
                    $requestMethod = "DELETE";
					try {
						Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $requestMethod, $requestUrl;
						Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl;
					    }
					catch {
						Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType;
						throw $_;
					    }
                    }
## Update section: Update the AU, add/remove users or groups, add/remove administrators with area roles.
                "Update" {
					$requestUrl = "$script:graphBaseUrl/administrativeUnits/{0}" -f $result.GraphResource.Id;
					$requestMethod = "PATCH";
					$requestBody = @{};
                    try {
                        foreach ($change in $result.Changes){
                            switch ($change.Property){
    ## Add/Remove Users
                                "members"{
                                    foreach ($action in $change.Actions.Keys) {
                                        switch ($action){
                                            "Add"{
                                                $url = "$script:graphBaseUrl/administrativeUnits/{0}/members/`$ref" -f $result.GraphResource.Id;
                                                $method = "POST";
                                                $change.Actions[$action] | ForEach-Object {													
													$body = @{ "@odata.id" = "$script:graphBaseUrl/users/{0}" -f $_ } | ConvertTo-Json -ErrorAction Stop;
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body;
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body;
												}
                                            }
                                            "Remove" {
                                                $method = "DELETE";
												$change.Actions[$action] | ForEach-Object {
													$url = "$script:graphBaseUrl/administrativeUnits/{0}/members/{1}/`$ref" -f $result.GraphResource.Id, $_;
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $method, $url;
													Invoke-MgGraphRequest -Method $method -Uri $url;
												}
                                            }
                                            }
                                        }
                                    }
    ## Adding/Removing Groups
                                "groups" {
                                    foreach ($action in $change.Actions.Keys) {
                                        switch ($action){
                                            "Add"{
                                                $url = "$script:graphBaseUrl/administrativeUnits/{0}/members/`$ref" -f $result.GraphResource.Id;
                                                $method = "POST";
                                                $change.Actions[$action] | ForEach-Object {													
													$body = @{ "@odata.id" = "$script:graphBaseUrl/groups/{0}" -f $_ } | ConvertTo-Json -ErrorAction Stop;
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body;
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body;
												}
                                            }
                                            "Remove" {
                                                $method = "DELETE";
												$change.Actions[$action] | ForEach-Object {
													$url = "$script:graphBaseUrl/administrativeUnits/{0}/members/{1}/`$ref" -f $result.GraphResource.Id, $_;
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $method, $url;
													Invoke-MgGraphRequest -Method $method -Uri $url;
												}
                                            }
                                            }
                                        }
                                    }
    ## Adding/Removing Administrators with Area Role
                                "scopedRoleMembers" {
                                    foreach ($action in $change.Actions.Keys) {
                                        switch ($action){
                                            "Add"{
                                                $requestUrl = "$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers/`$ref" -f $result.GraphResource.Id;
                                                $requestMethod = "POST";
                                            }
                                            "Remove" {
                                                $requestUrl = "$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers/`$ref" -f $result.GraphResource.Id;
                                                $requestMethod = "DELETE";
                                            }
                                            }
                                        }
                                    }
    ## Customise the administrative unit (description / visibility)
                                default {
                                    foreach ($action in $change.Actions.Keys){
                                        switch ($action) {
                                            "Set" {
                                                $requestBody[$change.Property] = $change.Actions[$action];
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            if ($requestBody.Keys -gt 0) {
                                $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop;
                                Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody;
                                Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody;
                            }
                        }
                    catch{
                        Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType;
						throw $_;
                        }
                    }
## Idle section: Nothing happens here, please move on
                "NoActionRequired" {}
                default { Write-PSFMessage -Level Warning -String "TMF.Invoke.ActionTypeUnknown" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, (Get-ActionColor -Action $result.ActionType), $result.ActionType; }
            }
        }
    }
    end {}
}