function Validate-ConditionalAccessApplications
{
	[CmdletBinding()]
	Param (
		[string[]] $includeApplications,
		[string[]] $excludeApplications,
		[string[]] $includeUserActions,
		[object] $applicationFilter,
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
			switch ($property.Key) {
				"includeUserActions" {
					$validated = @($property.Value)
				}
				"applicationFilter" {
					if ($null -eq $property.value) {
						$validated = $null
					}
					else {
						$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
						$validated = & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @validated -Cmdlet $Cmdlet
					}					
				}
				{$_ -in @("includeApplications","excludeApplications")} {
					$validated = @($property.Value | Foreach-Object {Resolve-Application -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
				}
			}
			$hashtable[$property.Key] = $validated
		}
	}
	end
	{
		$hashtable
	}
}
