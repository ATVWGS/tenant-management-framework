function Validate-AssignmentReviewSettings
{
	[CmdletBinding()]
	Param (
		[Parameter (Mandatory = $true)]
		[ValidateSet("keepAccess", "removeAccess", "acceptAccessRecommendation")]
		[string] $expirationBehavior,
		[bool] $isEnabled,
		[bool] $isRecommendationEnabled,
		[bool] $isReviewerJustificationRequired,
		[bool] $isSelfReview,
		[object[]] $primaryReviewers,
		[object[]] $fallbackReviewers,
		[object] $schedule,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$parentResourceName = "accessPackageAssignmentPolicies"
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$hashtable = @{}
		foreach ($property in ($PSBoundParameters.GetEnumerator() | Where-Object {$_.Key -ne "Cmdlet"})) {
			if ($script:supportedResources[$parentResourceName]["validateFunctions"].ContainsKey($property.Key)) {
				if ($property.Value.GetType().Name -eq "Object[]") {
					$validated = @()
					foreach ($value in $property.Value) {
						$dummy = $value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
						$validated += & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @dummy -Cmdlet $Cmdlet
					}					
				}
				else {
					if ($property.Value) {
						$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
						$validated = & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @validated -Cmdlet $Cmdlet
					}
					else {
						$validated = @()
					}
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
