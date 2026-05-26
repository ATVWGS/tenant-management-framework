function Validate-AdminConsentRequestReviewers
{
	<#
		.SYNOPSIS
			Validates reviewers of adminConsentRequestPolicy

		.PARAMETER reference
			The id, displayName, userPrincipalName or mailNickname of the referenced resource.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = "Default")]
		[string] $reference,
		[ValidateSet("singleUser", "groupMembers", "roleMembers")]
		[string] $type = "singleUser",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$parentResourceName = "adminConsentRequestPolicy"
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
			"roleMembers" {
				$id = Resolve-DirectoryRoleDefinition -InputReference $reference -SearchInDesiredConfiguration -DontFailIfNotExisting -Cmdlet $PSCmdlet
				$hashtable["query"] = "/beta/roleManagement/directory/roleAssignments?`$filter=roleDefinitionId eq '$($id)'"
			}
        }
	}
	end
	{
		$hashtable
	}
}
