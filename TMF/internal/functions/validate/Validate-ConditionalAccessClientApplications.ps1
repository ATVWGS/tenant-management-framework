function Validate-ConditionalAccessClientApplications
{
	[CmdletBinding()]
	Param (
		[string[]] $includeServicePrincipals,
		[string[]] $excludeServicePrincipals,
		[object] $servicePrincipalFilter,
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
				"servicePrincipalFilter" {
					if ($null -eq $property.value) {
						$validated = $null
					}
					else {
						$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
						$validated = & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @validated -Cmdlet $Cmdlet
					}					
				}
				{$_ -in @("includeServicePrincipals","excludeServicePrincipals")} {
					$validated = @($property.Value | Foreach-Object {Resolve-ServicePrincipal -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
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
