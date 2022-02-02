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

    begin{}

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
				$id = Resolve-DirectoryRole -InputReference $reference -Cmdlet $PSCmdlet
				$hashtable["query"] = "/beta/roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal&`$filter=(isof(principal,'microsoft.graph.servicePrincipal') and roleDefinitionId eq '$($this.getId())')"
			}
		}
		#return $hashtable
		<#
		$scopeObject = [PSCustomObject]@{
			type = $type
		}

        Add-Member -InputObject $scopeObject -MemberType NoteProperty -Name "@odata.type" -Value ("#microsoft.graph.{0}" -f $type)

        if ($type -in @("group","directoryRole")) {
            Add-Member -InputObject $scopeObject -MemberType NoteProperty -Name reference -Value $reference
            Add-Member -InputObject $scopeObject -MemberType ScriptMethod -Name getId -Value {
				switch ($this.type) {
					"group" {
						Resolve-Group -InputReference $this.reference -Cmdlet $PSCmdlet
					}
					"directoryRole" {
						Resolve-DirectoryRole -InputReference $this.reference -Cmdlet $PSCmdlet
					}
				}
			}
        }

        Add-Member -InputObject $scopeObject -MemberType ScriptMethod -Name prepareBody -Value {
			$hashtable = @{				
				"@odata.type" = "#microsoft.graph.accessReviewQueryScope"
				"queryType" = "MicrosoftGraph"
				"queryRoot" = ""
			}
			if ($this.getId) {
				switch ($this.type) {
					"group" {
						$hashtable["query"] = "/v1.0/groups/$($this.getId())/transitiveMembers/microsoft.graph.user"
					}
					"directoryRole" {
						$hashtable["query"] = "/beta/roleManagement/directory/roleAssignmentScheduleInstances?`$expand=principal&`$filter=(isof(principal,'microsoft.graph.servicePrincipal') and roleDefinitionId eq '$($this.getId())')"
					}
				}
				
			}
			return $hashtable
		}
		#>
    }

    end 
    {
		$hashtable
        #$scopeObject.prepareBody()
    }
}