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
			if ($alreadyLoaded.sourceConfig -ne $sourceConfig) {
				Stop-PSFFunction -String "TMF.RegisterComponent.AlreadyLoaded" -StringValues "group", $displayName, $alreadyLoaded.sourceConfig
			}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		$object = [PSCustomObject] @{
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
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration["groups"][$script:desiredConfiguration["groups"].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration["groups"] += $object
		}		
	}
}
