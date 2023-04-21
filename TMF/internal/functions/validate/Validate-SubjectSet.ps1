function Validate-SubjectSet
{
	<#
		.SYNOPSIS
			Validates the properties of a subjectSet complex type

		.PARAMETER reference
			The id, displayName, userPrincipalName or mailNickname of the referenced resource.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = "Default")]
		[string] $reference,
		[ValidateSet("attributeRuleMembers","singleUser","singleServicePrincipal","groupMembers", "connectedOrganizationMembers", "requestorManager", "internalSponsors", "externalSponsors", "targetManager","targetApplicationOwners")]
		[string] $type = "singleUser",
		[Parameter(Mandatory = $true, ParameterSetName = "RequestorManager")]
		[int] $managerLevel,
		[Parameter(Mandatory = $true, ParameterSetName = "attributeRuleMembers")]
		[string] $membershipRule,
		[string] $description,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		if ($managerLevel) {
			$type = "requestorManager"
		}

		if ($membershipRule) {
			$type = "attributeRuleMembers"
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$subjectSetObject = [PSCustomObject]@{
			type = $type
		}

		Add-Member -InputObject $subjectSetObject -MemberType NoteProperty -Name "@odata.type" -Value ("#microsoft.graph.{0}" -f $type)
		if ($type -in @("singleUser", "singleServicePrincipal", "groupMembers", "connectedOrganizationMembers")) {
			Add-Member -InputObject $subjectSetObject -MemberType NoteProperty -Name reference -Value $reference
			Add-Member -InputObject $subjectSetObject -MemberType ScriptMethod -Name getId -Value {
				switch ($this.type) {
					"singleUser" {
						Resolve-User -InputReference $this.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
					}
                    "singleServicePrincipal" {
                        Resolve-ServicePrincipal -InputReference $this.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
                    }
					"groupMembers" {
						Resolve-Group -InputReference $this.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
					}
					"connectedOrganizationMembers" {
						Resolve-ConnectedOrganization -InputReference $this.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
					}
				}
			}
			
		}
		if ($type -eq "requestorManager") {
			Add-Member -InputObject $subjectSetObject -MemberType NoteProperty -Name managerLevel -Value $managerLevel
		}

		if ($type -eq "attributeRuleMembers") {
			Add-Member -InputObject $subjectSetObject -MemberType NoteProperty -Name membershipRule -Value $membershipRule
			Add-Member -InputObject $subjectSetObject -MemberType NoteProperty -Name description -Value $description
		}

		Add-Member -InputObject $subjectSetObject -MemberType ScriptMethod -Name prepareBody -Value {
			$hashtable = @{				
				"@odata.type" = $this."@odata.type"
			}
			if ($this.getId) {
				switch ($this.type) {
					"singleUser" {
						$hashtable["userId"] = $this.getId()
					}
                    "singleServicePrincipal" {
                        $hashtable["servicePrincipalId"] = $this.getId()
                    }
					"groupMembers" {
						$hashtable["groupId"] = $this.getId()
					}
					"connectedOrganizationMembers" {
						$hashtable["connectedOrganizationId"] = $this.getId()
					}
				}
			}
			if ($this.managerLevel) {$hashtable["managerLevel"] = $this.managerLevel}
			if ($this.membershipRule) {$hashtable["membershipRule"] = $this.membershipRule} 
			if ($this.description) {$hashtable["description"] = $this.description}
			return $hashtable
		}
	}
	end
	{
		$subjectSetObject
	}
}
