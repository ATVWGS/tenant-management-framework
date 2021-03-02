function Test-TmfGroup
{
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = "Beautify")]
		[switch] $Beautify,
		[Parameter(ParameterSetName = "Beautify")]
		[switch] $DoNotShowPropertyChanges
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
						$change = [PSCustomObject] @{
							Property = $property										
							Actions = $null
						}
						switch ($property) {
							"members" {
								$change.Actions = (Compare-UserList -ReferenceList (Get-MgGroupMember -GroupId $resource.Id).Id -DifferenceList $definition.members)
							}
							"owners" {
								$change.Actions = (Compare-UserList -ReferenceList (Get-MgGroupOwner -GroupId $resource.Id).Id -DifferenceList $definition.owners)
							}
							"groupTypes" {}
							default {
								if ($definition.$property -ne $resource.$property) {
									$change.Actions = @{"Set" = $definition.$property}
								}
							}
						}
						if ($change.Actions) {$changes += $change}
					}

					if ($changes.count -gt 0) { $result = New-TestResult @result -Changes $changes -ActionType "Update"}
					else { $result = New-TestResult @result -ActionType "NoActionRequired" }
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
				if (!$DoNotShowPropertyChanges) {
					if ($result.ActionType -eq "Update") {
						foreach ($change in $result.Changes) {
							foreach ($action in $change.Actions.Keys) {
								Write-PSFMessage -Level Host -String "TMF.TestResult.BeautifyPropertyChange" -StringValues $tenant.displayName, $result.ResourceName, $result.ResourceType, $change.Property, $action, ($change.Actions.$action -join ", ")
							}
						}
					}
				}				
			}
			else { $result }
		}
	}
}
