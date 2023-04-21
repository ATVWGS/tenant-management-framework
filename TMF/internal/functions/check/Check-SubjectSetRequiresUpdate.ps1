function Check-SubjectSetRequiresUpdate
{
    <#
        .SYNOPSIS
            Check whether a subjectSet list has changed.
        .DESCRIPTION
            Returns $true if subjectSet list has changed.
        .PARAMETER Reference
            Should always be the subjectSet from Azure AD (or Graph).
        .PARAMETER Difference 
            Should be the defined TMF subjectSet.
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
                switch ($set.type) {
                    "groupMembers" {
                        if ($set.getId() -notin $Reference.groupId) { return $true }
                    }
                    "singleUser" {
                        if ($set.getId() -notin $Reference.userId) { return $true }
                    }
                    "singleServicePrincipal" {
                        if ($set.getId() -notin $Reference.servicePrincipalId) { return $true }
                    }
                    "connectedOrganizationMembers" {
                        if ($set.getId() -notin $Reference.connectedOrganizationId) { return $true }
                    }
                }
            }

            if ($set.managerLevel) {
                if ($set.managerLevel -notin $Reference.managerLevel) {
                    return $true
                }
            }
            if ($set."@odata.type" -notin $Reference."@odata.type") {
                return $true
            }
            if ($set.membershipRule) {
                if ($set.membershipRule -notin $Reference.membershipRule) {
                    return $true
                }
            }
        }
	}
}
