function Validate-ConditionalAccessAuthenticationStrength
{
	[CmdletBinding()]
	Param (
		[string] $displayName,
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
                "displayName" {
                    if ($property.Value) {
                        $id = Resolve-AuthenticationStrengthPolicy -InputReference $property.Value -SearchInDesiredConfiguration -Cmdlet $Cmdlet
                    }
                }
            }
        }
        $hashtable["id"] = $id
	}
	end
	{
        $hashtable
	}
}