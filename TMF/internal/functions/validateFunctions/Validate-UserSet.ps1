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
		[Parameter(Mandatory = $true, ParameterSetName = "Default")]
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

		if ($type -in @("singleUser", "groupMembers", "connectedOrganizationMembers")) {
			Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name reference -Value $reference
			Add-Member -InputObject $userSetObject -MemberType ScriptMethod -Name id -Value {
				switch ($this.type) {
					"singleUser" {
						Resolve-User -InputReference $this.reference -Cmdlet $PSCmdlet
					}
					"groupMembers" {
						Resolve-Group -InputReference $this.reference -Cmdlet $PSCmdlet
					}
					"connectedOrganizationMembers" {
						Resolve-ConnectedOrganization -InputReference $this.reference -Cmdlet $PSCmdlet
					}
				}
			}
			
		}
		if ($type -eq "requestorManager") {
			Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name managerLevel -Value $managerLevel
		}

		Add-Member -InputObject $userSetObject -MemberType ScriptMethod -Name prepareBody -Value {
			$hashtable = @{
				"@odata.type" = "#microsoft.graph.{0}" -f $this.type
				isBackup = $this.isBackup					
			}
			if ($this.id) {$hashtable["id"] = $this.id()}
			if ($this.managerLevel) {$hashtable["managerLevel"] = $this.managerLevel}
			$hashtable
		}
	}
	end
	{
		$userSetObject
	}
}
