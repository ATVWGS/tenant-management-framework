function Test-TmfDirectoryRole {
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
		$resourceName = "DirectoryRoles"
		$tenant = Get-MgOrganization -Property displayName, Id
	}
	process
	{
		foreach ($definition in $script:desiredConfiguration[$resourceName]) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property) {
					if ($definition.$property.GetType().Name -eq "String") {
						$definition.$property = Resolve-String -Text $definition.$property
					}
				}
			}

            $result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'directoryRole'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}
			if ($definition.present) {
				if ($definition.roleID) {
					$result["GraphResource"] = $definition.roleID
					try {
						$roleMembers = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/{0}/members" -f $definition.roleID)).Value
					}
					catch {
						Write-PSFMessage -Level Warning -String 'TMF.Error.QueryWithFilterFailed' -StringValues $filter -Tag 'failed'
						$exception = New-Object System.Data.DataException("Query with filter $filter against Microsoft Graph failed. Error: $_")
						$errorID = 'QueryWithFilterFailed'
						$category = [System.Management.Automation.ErrorCategory]::NotSpecified
						$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
						$cmdlet.ThrowTerminatingError($recordObject)
					}

					if ($roleMembers) {

						if ($definition.memberIDs) {

							if (Compare-Object $roleMembers.id $definition.memberIDs) {
								$result = New-TestResult @result -ActionType "Change members"
							}
							else {
								$result = New-TestResult @result -ActionType "NoActionRequired"
							}
						}
						else {
							$result = New-TestResult @result -ActionType "Change members"
						}
					}
					else {
						if ($definition.memberIDs) {
							$result = New-TestResult @result -ActionType "Change members"
						}
						else {
							$result = New-TestResult @result -ActionType "NoActionRequired"
						}
					}
				}
				else {
					$result = New-TestResult @result -ActionType "Activate"
				}
			}
			else {
				$result = New-TestResult @result -ActionType "NoActionRequired"
			}
            $result
        }

    }

    end {}
}