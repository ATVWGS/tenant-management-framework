function Validate-AccessReviewScope
{
	[CmdletBinding()]
	Param (
        [ValidateSet("group","directoryRole")]
        [string] $type,
		[string] $subScope,
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
		
		switch ($type) {
			"group" {
				$hashtable = @{				
					"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
					"queryType" = "MicrosoftGraph"
					"queryRoot" = $null
				}
				$id = Resolve-Group -InputReference $reference -Cmdlet $PSCmdlet
				$hashtable["query"] = "/v1.0/groups/$($id)/transitiveMembers/microsoft.graph.user"
			}
			"directoryRole" {
				$id = Resolve-DirectoryRoleTemplate -InputReference $reference -Cmdlet $PSCmdlet
				switch ($subScope) {
					"servicePrincipals" {
						$hashtable = @{				
							"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
							"queryType" = "MicrosoftGraph"
							"queryRoot" = $null
							"query" = "/beta/roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal&`$filter=(isof(principal,'microsoft.graph.servicePrincipal') and roleDefinitionId eq '$($Id)')"
						}
					}
					"users_groups" {
						$hashtable = @()
						$hashtable += @{
							"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
							"queryType" = "MicrosoftGraph"
							"queryRoot" = $null
							"query" = "/beta/roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal&`$filter=(assignmentType eq 'Assigned' and isof(principal,'microsoft.graph.user') and roleDefinitionId eq '$($Id)')"
						}
						$hashtable += @{
							"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
							"queryType" = "MicrosoftGraph"
							"queryRoot" = $null
							"query" = "/beta/roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal&`$filter=(assignmentType eq 'Assigned' and isof(principal,'microsoft.graph.group') and roleDefinitionId eq '$($Id)')"
						}
					}
				}
			}
		}
    }

    end 
    {
		$hashtable
    }
}