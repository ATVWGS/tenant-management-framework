function Invoke-TmfAdministrativeUnit
{
	[CmdletBinding()]
	Param (
        [string[]] $SpecificResources,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "administrativeUnits"
		if (!$script:desiredConfiguration[$resourceName]) {
			Stop-PSFFunction -String "TMF.NoDefinitions" -StringValues "administrativeUnits"
			return
		}
		Test-GraphConnection -Cmdlet $Cmdlet
	}

    process
    {
        if(Test-PSFFunctionInterrupt) {return}
        if ($SpecificResources) {
        	$testResults = Test-TmfAdministrativeUnit -SpecificResources $SpecificResources -Cmdlet $Cmdlet
		}
		else {
			$testResults = Test-TmfAdministrativeUnit -Cmdlet $Cmdlet
		}

        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                "Create" {
                        $requestUrl = "$script:graphBaseUrl/administrativeUnits"
                        $requestMethod = "POST"
                        $requestBody  = @{
                            "displayName" = $result.DesiredConfiguration.displayName
                            "description" = $result.DesiredConfiguration.description
                            "visibility"  = $result.DesiredConfiguration.visibilty
                        }

                        $membersToAdd = @()
                        @("members", "groups") | Foreach-Object {
                            if ($result.DesiredConfiguration.Properties() -contains $_) {                                
                                switch ($_) {
                                    "members" {
                                        $membersToAdd += $result.DesiredConfiguration.$_ | Foreach-Object {
                                            @{ "@odata.id" = "$script:graphBaseUrl/users/{0}" -f (Resolve-User -InputReference $_ -Cmdlet $Cmdlet)}
                                        }
                                    }
                                    "groups" {
                                        $membersToAdd += $result.DesiredConfiguration.$_ | Foreach-Object {
                                            @{ "@odata.id" = "$script:graphBaseUrl/groups/{0}" -f (Resolve-Group -InputReference $_ -Cmdlet $Cmdlet)}
                                        }
                                    }
                                }
                            }
                        }

                        $scopedRoleMemberships = @()
                        if ($result.DesiredConfiguration.Properties() -contains "scopedRoleMembers") {  
                            $scopedRoleMemberships += $result.DesiredConfiguration.scopedRoleMembers | Foreach-Object {
                                $identityId = Resolve-User -InputReference $_.identity -Cmdlet $Cmdlet -DontFailIfNotExisting
                                if (-Not $identityId) {
                                    $identityId = Resolve-Group -InputReference $_.identity -Cmdlet $Cmdlet
                                }

                                @{
                                    "roleId" = Resolve-DirectoryRole -InputReference $_.role -Cmdlet $Cmdlet
                                    "roleMemberInfo" = @{
                                        "id" = $identityId
                                    }
                                }
                            }
                        }

                        $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
                        Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                        $resultObject = Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody                        

                        if ($membersToAdd.count -gt 0) {
                            $requestMethod = "POST"
                            $requestUrl = "{0}/{1}/members/`$ref" -f $requestUrl, $resultObject.id                            
                            $membersToAdd | Foreach-Object {
                                $requestBody = ($_ | ConvertTo-Json -ErrorAction Stop)
                                Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                            }
                        }

                        if ($scopedRoleMemberships.count -gt 0) {
                            $requestMethod = "POST"
                            $requestUrl = "$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers" -f $resultObject.id
                            $scopedRoleMemberships | Foreach-Object {
                                $requestBody = ($_ | ConvertTo-Json -ErrorAction Stop)
                                Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                                Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody | Out-Null
                            }
                        }
                    }
                    catch {
                        Write-PSFMessage -Level Error -String "TMF.Invoke.ActionFailed" -StringValues $result.Tenant, $result.ResourceType, $result.ResourceName, $result.ActionType
                        throw $_
					}
                "Delete" {
                    $requestUrl = "$script:graphBaseUrl/administrativeUnits/{0}" -f $result.GraphResource.Id
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
					$requestUrl = "$script:graphBaseUrl/administrativeUnits/{0}" -f $result.GraphResource.Id
					$requestMethod = "PATCH"
					$requestBody = @{}
                    try {
                        foreach ($change in $result.Changes) {
                            switch ($change.Property){
                                {($_ -eq "members") -or ($_ -eq "groups")} {
                                    foreach ($action in $change.Actions.Keys) {
                                        $memberEndpointName = $(if ($change.Property -eq "members") { "users" } else { "groups" })
                                        switch ($action) {
                                            "Add" {
                                                $url = "$script:graphBaseUrl/administrativeUnits/{0}/members/`$ref" -f $result.GraphResource.Id
                                                $method = "POST"
                                                $change.Actions[$action] | ForEach-Object {													
													$body = @{ "@odata.id" = "$script:graphBaseUrl/$memberEndpointName/{0}" -f $_ } | ConvertTo-Json -ErrorAction Stop
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body
												}
                                            }
                                            "Remove" {
                                                $method = "DELETE"
												$change.Actions[$action] | ForEach-Object {
													$url = "$script:graphBaseUrl/administrativeUnits/{0}/members/{1}/`$ref" -f $result.GraphResource.Id, $_
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $method, $url
													Invoke-MgGraphRequest -Method $method -Uri $url
												}
                                            }
                                        }
                                    }
                                }
                                "scopedRoleMembers" {
                                    foreach ($action in $change.Actions.Keys) {
                                        switch ($action){
                                            "Add"{
                                                $url = "$script:graphBaseUrl/administrativeUnits/{0}/scopedRoleMembers" -f $result.GraphResource.Id
                                                $method = "POST"
                                                $change.Actions[$action] | ForEach-Object {													
													$body = @{
                                                        "roleId" = Resolve-DirectoryRole -InputReference $_.role -Cmdlet $Cmdlet
                                                        "roleMemberInfo" = @{
                                                            "id" = $_.identity
                                                        }
                                                    } | ConvertTo-Json -ErrorAction Stop
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $method, $url, $body
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body | Out-Null
												}
                                            }
                                            "Remove" {                                                
                                                $method = "DELETE"
                                                $change.Actions[$action] | ForEach-Object {
                                                    $url = "$script:graphBaseUrl/directory/administrativeUnits/{0}/scopedRoleMembers/{1}" -f $result.GraphResource.Id, $_
													Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequest" -StringValues $method, $url
													Invoke-MgGraphRequest -Method $method -Uri $url -Body $body | Out-Null
												}
                                            }
                                        }
                                    }
                                }
                                default {
                                    foreach ($action in $change.Actions.Keys){
                                        switch ($action) {
                                            "Set" {
                                                $requestBody[$change.Property] = $change.Actions[$action]
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        if ($requestBody.Keys -gt 0) {
                            $requestBody = $requestBody | ConvertTo-Json -ErrorAction Stop
                            Write-PSFMessage -Level Verbose -String "TMF.Invoke.SendingRequestWithBody" -StringValues $requestMethod, $requestUrl, $requestBody
                            Invoke-MgGraphRequest -Method $requestMethod -Uri $requestUrl -Body $requestBody
                        }
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
		Load-TmfConfiguration -Cmdlet $Cmdlet
	}
}