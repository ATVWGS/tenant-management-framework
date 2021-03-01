function Register-TmfGroup
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string] $description,
		[string[]] $groupTypes,		
		[bool] $securityEnabled = $true,
		[bool] $mailEnabled = $false,
		[Parameter(Mandatory = $true)]
		[string] $mailNickname,
		[string[]] $members,
		[string[]] $owners,		
		[bool] $present = $true,
		[string] $sourceConfig = "<Custom>"
	)
	
	begin
	{
		if (!$script:desiredConfiguration["groups"]) {
			$script:desiredConfiguration["groups"] = @()
		}
		if ($script:desiredConfiguration["groups"].displayName -contains $displayName) {
			$alreadyLoaded = $script:desiredConfiguration["groups"] | ? {$_.displayName -eq $displayName}
			Stop-PSFFunction -String "TMF.RegisterComponent.AlreadyLoaded" -StringValues "group", $displayName, $alreadyLoaded.sourceConfig
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		$script:desiredConfiguration["groups"] += [PSCustomObject] @{
			displayName = $displayName
			description = $description
			groupTypes = $groupTypes
			securityEnabled = $securityEnabled
			mailEnabled = $mailEnabled
			mailNickname = $mailNickname
			members = $members
			owners = $owners
			present = $present
			sourceConfig = $sourceConfig
		}
	}
}
