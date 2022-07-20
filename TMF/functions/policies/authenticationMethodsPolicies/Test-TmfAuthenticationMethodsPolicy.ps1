function Test-TmfAuthenticationMethodsPolicy {
    <#
		.SYNOPSIS
			Test desired configuration against a Tenant.
		.DESCRIPTION
			Compare current configuration of a resource type with the desired configuration.
			Return a result object with the required changes and actions.
	#>
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "authenticationMethodsPolicies"
		$tenant = Get-MgOrganization -Property displayName, Id
	}
	process
	{
		foreach ($definition in $script:desiredConfiguration[$resourceName]) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'authenticationMethodsPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
				$resource = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationMethodsPolicy")
			}
			catch {
				Write-PSFMessage -Level Warning -String 'TMF.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
				$exception = New-Object System.Data.DataException("Query with filter $filter against Microsoft Graph failed. Error: $_")
				$errorID = 'QueryWithFilterFailed'
				$category = [System.Management.Automation.ErrorCategory]::NotSpecified
				$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
				$cmdlet.ThrowTerminatingError($recordObject)
			}

            $result["GraphResource"] = $resource
            $changes = @()

            foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "displayName", "sourceConfig"})) {
                $change = [PSCustomObject] @{
                    Property = $property										
                    Actions = @()
                }

                switch ($property) {
                    "authenticationMethodConfigurations" {

                        foreach ($method in $definition.$property) {
                            $methodChange = $false
                            $methodProperties = ($method | Get-Member -MemberType NoteProperty).Name
                            $resourceMethod = $resource.$property | Where-Object {$_.id -eq $method.id}
                            foreach ($methodProperty in $methodProperties) {
                                if ($method.$methodProperty.GetType().Name -in "Object[]", "Hashtable", "PSCustomObject") {
                                    switch ($method.$methodProperty.GetType().Name) {
                                        "Object[]" {
                                            $objectcount = $method.$methodProperty.count
                                            for ($i=0; $i -lt $objectcount; $i++) {
                                                foreach ($key in ($method.$methodProperty[$i] | Get-Member -MemberType NoteProperty).Name) {
                                                    if ($method.$methodProperty[$i].$key -ne $resourceMethod.$methodProperty[$i].$key) {
                                                        $methodChange = $true
                                                    }
                                                }
                                            }
                                        }
                                        "Hashtable" {
                                            if (Compare-Hashtable ($method.$methodProperty | ConvertTo-PSFHashtable) $resourceMethod.$methodProperty) {
                                                $methodChange = $true
                                            }
                                        }
                                        "PSCustomObject" {
                                            foreach ($item in ($method.$methodProperty | Get-Member -MemberType NoteProperty).Name) {
                                                if ($method.$methodProperty.$item -ne $resourceMethod.$methodProperty.$item) {
                                                    $methodChange = $true
                                                }
                                            }
                                        }
                                    }
                                }
                                else {
                                    if ($method.$methodProperty -ne $resourceMethod.$methodProperty) {
                                        $methodChange = $true
                                    }
                                }
                            }

                            if ($methodChange) {
                                $change.Actions += @{"Set" = $method.id}
                            }
                        }
                    }
                    "registrationEnforcement" {

                        $regEnfProperties = ($definition.$property.authenticationMethodsRegistrationCampaign | Get-Member -MemberType NoteProperty).Name
                        foreach ($item in $regEnfProperties) {
                            if ($definition.$property.authenticationMethodsRegistrationCampaign.$item.GetType().Name -in "Object[]", "Hashtable") {
                                switch ($definition.$property.authenticationMethodsRegistrationCampaign.$item.GetType().Name) {
                                    "Object[]" {

                                        if ($definition.$property.authenticationMethodsRegistrationCampaign.$item -and $resource.$property.authenticationMethodsRegistrationCampaign.$item) {
                                            if (Compare-Object ($definition.$property.authenticationMethodsRegistrationCampaign.$item | ConvertTo-PSFHashtable) $resource.$property.authenticationMethodsRegistrationCampaign.$item) {
                                                $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                            }
                                        }
                                        else {
                                            if (((-not ($definition.$property.authenticationMethodsRegistrationCampaign.$item)) -and $resource.$property.authenticationMethodsRegistrationCampaign.$item) -or ($definition.$property.authenticationMethodsRegistrationCampaign.$item -and (-not ($resource.$property.authenticationMethodsRegistrationCampaign.$item)))) {
                                                $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                            }
                                        }
                                    }
                                    "Hashtable" {
                                        if (-not (Compare-Hashtable $definition.$property.authenticationMethodsRegistrationCampaign.$item $resource.$property.authenticationMethodsRegistrationCampaign.$item)) {
                                            $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                        }
                                    }
                                }
                            }
                            else {
                                if ($definition.$property.authenticationMethodsRegistrationCampaign.$item -ne $resource.$property.authenticationMethodsRegistrationCampaign.$item){
                                    $change.Actions = @{"Set" = $definition.$property.authenticationMethodsRegistrationCampaign.$item}
                                }
                            }
                        }
                    }
                }
                if ($change.Actions) {$changes += $change}
            }

            if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
            else { $result = New-TestResult @result -ActionType "NoActionRequired" }

            $result            
        }
    }
    
    end {}
}