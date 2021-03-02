function Test-TmfGroup
{
	[CmdletBinding()]
	Param (
		[switch] $Beautify
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
		$tenant = Get-MgOrganization -Property displayName, Id
		[regex] $guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'
	}
	process
	{
		$results = @()
		foreach ($definition in $script:desiredConfiguration["groups"]) {

			$result = @{
				Tenant = "{0} (Id: {1})" -f $tenant.displayName, $tenant.Id
				ResourceType = 'Group'
				ResourceName = (Resolve-String -Text $definition.displayName)
				DesiredConfiguration = $definition
			}

			$resource = Get-MgGroup -Filter "displayName eq '$($definition.displayName)'"			

			if ($resource) {
				if ($definition.present) {
					$changes = @()
					foreach ($property in ($definition.Properties() | ? {$_ -notin "displayName", "present", "sourceConfig"})) {
						switch ($property) {
							"members" {
								if ("DynamicMembership" -notin $definition.groupTypes) {
									$currentMembers = (Get-MgGroupMember -GroupId $resource.Id).Id
									$requiredMembers = ($definition.members | foreach {
										if ($_ -match $guidRegex) {
											Get-MgUser -UserId $_
										}
										else {
											Get-MgUser -Filter "userPrincipalName eq '$_'"
										}
									}).Id
									$compare = Compare-Object -ReferenceObject $currentMembers -DifferenceObject $requiredMembers
									$changes += [PSCustomObject] @{
										Property = $property
										Changes = @{
											"Add" = ($compare | ? {$_.SideIndicator -eq "=>"}).InputObject
											"Remove" = ($compare | ? {$_.SideIndicator -eq "<="}).InputObject
										}
									}
								}								
							}
							"owners" {}
							"groupTypes" {}
							default {
								#Compare-Object -ReferenceObject $resource -DifferenceObject $definition -Property $property
							}
						}
						$global:test = $changes
					}
					$result = New-TestResult @result -ActionType "Update"
				}
				else {
					$result = New-TestResult @result -ActionType "Delete"
				}
			}
			else {
				if ($definition.present) {					
					$result = New-TestResult @result -ActionType "Create"
				}
				else {					
					$result = New-TestResult @result -ActionType "NoActionRequired"
				}
			}

			if ($Beautify) {
				Write-PSFMessage -Level Host -String "TMF.TestResult.BeautifySimple" -StringValues $tenant.displayName, $result.ResourceName, $result.ResourceType, $result.ActionType, (Get-ActionColor -Action $result.ActionType)
			}
			else { $result }
		}
	}
	end
	{
	
	}
}
