function Check-UserSetRequiresUpdate
{
    <#
        .SYNOPSIS
            Check whether a userSet list has changed.
        .DESCRIPTION
            Returns $true if userSet list has changed.
        .PARAMETER Reference
            Should always be the userSet from Azure AD (or Graph).
        .PARAMETER Difference 
            Should be the defined TMF userSet.
    #>
	[CmdletBinding()]
	Param (
		[object[]] $Reference,
		[object[]] $Difference,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)	
	
	process
	{
        if ($Difference.Count -eq 0 -and $Reference.Count -eq 0) { return }
        if ($Difference.Count -ne $Reference.Count) {
			return $true
		}
		
        foreach ($set in $Difference) {
            if ($set.id) {
                if ($set.id -notin $Reference.id) { return $true }
            }
            elseif ($set.getId) {
                if ($set.getId() -notin $Reference.id) { return $true }
            }

            if ($set.managerLevel) {
                if ($set.managerLevel -notin $Reference.managerLevel) {
                    return $true
                }
            }
            if ($set."@odata.type" -notin $Reference."@odata.type") {
                return $true
            }
        }
	}
}
