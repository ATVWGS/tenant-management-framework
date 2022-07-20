function Test-TmfAuthenticationFlowsPolicy {
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
		$resourceName = "authenticationFlowsPolicies"
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
				ResourceType = 'authenticationFlowsPolicy'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

            try {
				$resource = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/policies/authenticationFlowsPolicy")
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

            if ($definition.selfServiceSignUp.isEnabled -ne $resource.selfServiceSignUp.isEnabled) {
                $change = [PSCustomObject] @{
                    Property = "isEnabled"										
                    Actions = @{"Set" = $definition.selfServiceSignUp.isEnabled}
                }

                $changes += $change
            }

            if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
            else { $result = New-TestResult @result -ActionType "NoActionRequired" }

            $result
        }
    }

    end {}
}