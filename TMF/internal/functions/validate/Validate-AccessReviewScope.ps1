function Validate-AccessReviewScope
{
	[CmdletBinding()]
	Param (
        [ValidateSet("group","directoryRole")]
        [string] $type,
        [string] $reference,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

    begin{
		$parentResourceName = "accessReviews"
	}

    process 
    {
        if (Test-PSFFunctionInterrupt) { return }				
		
		$hashtable = @{				
			"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
			"queryType" = "MicrosoftGraph"
			"queryRoot" = $null
		}

		switch ($type) {
			"group" {
				$id = Resolve-Group -InputReference $reference -Cmdlet $PSCmdlet
				$hashtable["query"] = "/v1.0/groups/$($id)/transitiveMembers/microsoft.graph.user"
			}
			"directoryRole" {
				$id = Resolve-DirectoryRoleTemplate -InputReference $reference -Cmdlet $PSCmdlet
				$hashtable["query"] = "/beta/roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal&`$filter=(isof(principal,'microsoft.graph.servicePrincipal') and roleDefinitionId eq '$($Id)')"
			}
		}
    }

    end 
    {
		$hashtable
    }
}