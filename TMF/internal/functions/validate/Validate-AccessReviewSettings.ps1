function Validate-AccessReviewSettings
{
	[CmdletBinding()]
	Param (
		[bool] $mailNotificationsEnabled = $true,
        [bool] $reminderNotificationsEnabled = $true,
        [bool] $justificationRequiredOnApproval = $true,
        [bool] $defaultDecisionEnabled = $false,
        [string] $defaultDecision,
        [int] $instanceDurationInDays,
		[bool] $autoApplyDecisionsEnabled = $false,
        [bool] $recommendationsEnabled = $true,
        [object] $recurrence,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

    begin{
		$parentResourceName = "accessReviews"
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
					$validated = $property.Value | ConvertTo-PSFHashtable -Include $($script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key].Parameters.Keys)
					$validated = & $script:supportedResources[$parentResourceName]["validateFunctions"][$property.Key] @validated -Cmdlet $Cmdlet
				}				
			}
			else {
				if ($property.Value.GetType().Name -eq "Object[]") {
					$validated = @($property.Value | ConvertTo-PSFHashtable)
				}
				else {
					$validated = $property.Value
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