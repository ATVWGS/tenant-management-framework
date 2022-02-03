function Validate-ConditionalAccessConditionSet
{
	[CmdletBinding()]
	Param (
		[object] $applications,		
		[object] $users,		
		[object] $locations,
		[object] $devices,
		[object] $platforms,
		
		[ValidateSet("all", "browser", "mobileAppsAndDesktopClients", "exchangeActiveSync", "easSupported", "other")]
		[string[]] $clientAppTypes,
		[ValidateSet("low", "medium", "high", "hidden", "none")]
		[string[]] $signInRiskLevels,
		[ValidateSet("low", "medium", "high", "hidden", "none")]
		[string[]] $userRiskLevels,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$parentResourceName = "conditionalAccessPolicies"
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {
			if ($script:supportedResources[$parentResourceName]["validateFunctions"].ContainsKey($property.Key)) {
				if ($property.Value.GetType().BaseType -eq "System.Array") {
					$validated = @()
					foreach ($value in $property.Value) {
						$dummy = $value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
						$validated += & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @dummy -Cmdlet $Cmdlet
					}					
				}
				else {
					$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
					$validated = & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @validated -Cmdlet $Cmdlet
				}				
			}
			else {
				$validated = $property.Value
			}
			$hashtable[$property.Key] = $validated
		}
	}
	end
	{
		$hashtable
	}
}