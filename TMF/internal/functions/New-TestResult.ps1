function New-TestResult
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $ResourceType,
		[Parameter(Mandatory = $true)]
		[string] $ActionType,
		[Parameter(Mandatory = $true)]
		[string] $ResourceName,
		[object[]] $Changes,        
		$DesiredConfiguration,
		$GraphResource,
        [string] $Tenant
	)
	
	process
	{
		$object = [PSCustomObject]@{
			ActionType = $ActionType
			ResourceType = $ResourceType
			ResourceName = $ResourceName
			Changes = $Changes
			Tenant = $Tenant
			DesiredConfiguration = $DesiredConfiguration
			GraphResource = $GraphResource
		}
		Add-Member -InputObject $object -MemberType ScriptMethod -Name ToString -Value { $this.ResourceName } -Force
		$object
	}
}