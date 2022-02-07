function Validate-UserSet
{
	<#
		.SYNOPSIS
			Validates the properties of a userSet complex type

		.PARAMETER reference
			The id, displayName, userPrincipalName or mailNickname of the referenced resource.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = "Default")]
		[string] $reference,
		[ValidateSet("singleUser", "groupMembers", "connectedOrganizationMembers", "requestorManager", "internalSponsors", "externalSponsors")]
		[string] $type = "singleUser",
		[bool] $isBackup = $false,
		[Parameter(Mandatory = $true, ParameterSetName = "RequestorManager")]
		[int] $managerLevel,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		if ($managerLevel) {
			$type = "requestorManager"
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$userSetObject = [PSCustomObject]@{
			type = $type
			isBackup = $isBackup			
		}

		Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name "@odata.type" -Value ("#microsoft.graph.{0}" -f $type)
		if ($type -in @("singleUser", "groupMembers", "connectedOrganizationMembers")) {
			Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name reference -Value $reference
			Add-Member -InputObject $userSetObject -MemberType ScriptMethod -Name getId -Value {
				switch ($this.type) {
					"singleUser" {
						Resolve-User -InputReference $this.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
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
			Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name managerLevel -Value $managerLevel
		}

		Add-Member -InputObject $userSetObject -MemberType ScriptMethod -Name prepareBody -Value {
			$hashtable = @{				
				isBackup = $this.isBackup
				"@odata.type" = $this."@odata.type"
			}
			if ($this.getId) {$hashtable["id"] = $this.getId()}
			if ($this.managerLevel) {$hashtable["managerLevel"] = $this.managerLevel}
			return $hashtable
		}
	}
	end
	{
		$userSetObject
	}
}
