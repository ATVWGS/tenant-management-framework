function Validate-ConditionalAccessApplicationFilter
{
	[CmdletBinding()]
	Param (
        [ValidateSet("include", "exclude")]
		[string] $mode,
		[string] $rule,
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
			if ($property.Key -eq "mode") {
					$validated = $property.Value
            }
            else {
                $ruleValid = $true
                foreach ($item in ($rule.split(" ") | Where-Object {$_ -like "CustomSecurityAttribute*"})) {
                    if (-not (Resolve-CustomSecurityAttributeDefinition -InputReference $item.split(".")[1] -SearchInDesiredConfiguration -Cmdlet $Cmdlet)){
                        $ruleValid = $false
                    }
                }
                if (-not $ruleValid) {
                    throw "Rule $rule for applicationFilter is not valid. Cannot find referenced customSecurityAttributeDefinitions."
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