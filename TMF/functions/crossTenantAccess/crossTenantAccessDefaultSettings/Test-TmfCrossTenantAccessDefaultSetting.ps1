function Test-TmfCrossTenantAccessDefaultSetting
{
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
		$resourceName = "crossTenantAccessDefaultSettings"
		$tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
	}
	process
	{
		$definitions = $script:desiredConfiguration[$resourceName]
		
		foreach ($definition in $definitions) {
			foreach ($property in $definition.Properties()) {
				if ($definition.$property.GetType().Name -eq "String") {
					$definition.$property = Resolve-String -Text $definition.$property
				}
			}

			$result = @{
				Tenant = $tenant.displayName
				TenantId = $tenant.Id
				ResourceType = 'CrossTenantAccessDefaultSettings'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}
			
            try {
				$resource = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl1/policies/crossTenantAccessPolicy/default"))
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
            foreach ($property in ($definition.Properties() | Where-Object {$_ -notin "present", "sourceConfig", "displayname", "isServiceDefault"})) {
                $change = [PSCustomObject] @{
                    Property = $property										
                    Actions = $null
                }
				switch ($property) {
					{$_ -in @("b2bCollaborationInbound","b2bCollaborationOutbound","b2bDirectConnectInbound","b2bDirectConnectOutbound","tenantRestrictions")} {
						$same = $true
						foreach ($item in ($definition.$property | Get-Member -MemberType NoteProperty).Name) {
							if ($null -eq $definition.$property.$item) {
								if ($null -ne $resource.$property.$item) {
									$same = $false
								}
							}
							else {
								foreach ($subItem in ($definition.$property.$item | Get-Member -MemberType NoteProperty).Name) {
									switch ($definition.$property.$item.$subItem.getType().Name) {
										"String" {
											if ($definition.$property.$item.$subItem -ne $resource.$property.$item.$subItem) {
												$same = $false
											}
										}
										"Object[]" {
											if ($definition.$property.$item.$subItem.count -eq 1 -and $resource.$property.$item.$subItem.count -eq 1) {
												if (-not (Compare-Hashtable -ReferenceObject ($definition.$property.$item.$subItem | ConvertTo-PSFHashtable) -DifferenceObject ($resource.$property.$item.$subItem | ConvertTo-PSFHashtable))) {
													$same = $false
												}
											}
											else {
												if (Compare-Object -ReferenceObject ($definition.$property.$item.$subItem | ConvertTo-PSFHashtable) -DifferenceObject ($resource.$property.$item.$subItem | ConvertTo-PSFHashtable)) {
													$same = $false
												}
											}											
										}
										default {
											if (-not (Compare-Hashtable -ReferenceObject ($definition.$property.$item.$subItem | ConvertTo-PSFHashtable) -DifferenceObject ($resource.$property.$item.$subItem | ConvertTo-PSFHashtable))) {
												$same = $false
											}
										}
									}
								}
							}
						}
						if (-not $same) {
							$change.Actions = @{"Set" = $definition.$property}
						}
					}
					{$_ -in @("automaticUserConsentSettings","inboundTrust")} {
						if (-not (Compare-Hashtable -ReferenceObject ($definition.$property | ConvertTo-PSFHashtable) -DifferenceObject ($resource.$property | ConvertTo-PSFHashtable))) {
							$change.Actions = @{"Set" = $definition.$property}
						}
					}
					"invitationRedemptionIdentityProviderConfiguration" {
						$same = $true
						for ($i=0; $i -lt $definition.$property.primaryIdentityProviderPrecedenceOrder.count;$i++) {
							if ($definition.$property.primaryIdentityProviderPrecedenceOrder[$i] -ne $resource.$property.primaryIdentityProviderPrecedenceOrder[$i]) {
								$same = $false
							}
						}
						if (-not $same) {
							$change.Actions = @{"Set" = $definition.$property}
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
}
