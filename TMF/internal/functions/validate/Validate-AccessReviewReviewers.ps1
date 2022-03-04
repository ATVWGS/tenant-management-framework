function Validate-AccessReviewReviewers
{
	<#
		.SYNOPSIS
			Validates reviewers of access reviews

		.PARAMETER reference
			The id, displayName, userPrincipalName or mailNickname of the referenced resource.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = "Default")]
		[string] $reference,
		[ValidateSet("singleUser", "groupMembers")]
		[string] $type = "singleUser",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$parentResourceName = "accessReviews"
	}
	
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

        $hashtable = @{
            "queryType" = "MicrosoftGraph"
            "queryRoot" = $null
        }

        switch ($type) {
            "singleUser" {
                $id = Resolve-User -InputReference $reference -SearchInDesiredConfiguration -DontFailIfNotExisting -Cmdlet $PSCmdlet
                $hashtable["query"] = "/v1.0/users/$($id)"
            }
            "groupMembers" {
                $id = Resolve-Group -InputReference $reference -SearchInDesiredConfiguration -DontFailIfNotExisting -Cmdlet $PSCmdlet
				$hashtable["query"] = "/v1.0/groups/$($id)/transitiveMembers/microsoft.graph.user"
            }
        }
	}
	end
	{
		$hashtable
	}
}
