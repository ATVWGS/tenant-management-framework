function Validate-ConditionalAccessGrantControls
{
	[CmdletBinding()]
	Param (
		[ValidateSet("block", "mfa", "compliantDevice", "domainJoinedDevice", "approvedApplication", "compliantApplication", "passwordChange", "unknownFutureValue")]		
		[string[]] $builtInControls,
		[string[]] $customAuthenticationFactors,
        [Parameter(Mandatory = $true)]
		[ValidateSet("AND", "OR")]        
		[string] $operator,
		[string[]] $termsOfUse,
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
			elseif ($property.Key -eq "termsOfUse") {
				$validated = @($property.Value | Foreach-Object {Resolve-Agreement -InputReference $_ -SearchInDesiredConfiguration -Cmdlet $Cmdlet})
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
