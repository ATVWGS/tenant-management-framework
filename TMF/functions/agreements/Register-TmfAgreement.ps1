function Register-TmfAgreement
{
	[CmdletBinding(DefaultParameterSetName = 'IPRanges')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,

		[bool] $isViewingBeforeAcceptanceRequired = $true,
		[bool] $isPerDeviceAcceptanceRequired = $false,
		[string] $userReacceptRequiredFrequency,

		[object] $termsExpiration,
		[object[]] $files,

		[bool] $present = $true,

		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$componentName = "agreements"
		if (!$script:desiredConfiguration[$componentName]) {
			$script:desiredConfiguration[$componentName] = @()
		}

		if ($script:desiredConfiguration[$componentName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$componentName] | ? {$_.displayName -eq $displayName}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			displayName = $displayName
			isViewingBeforeAcceptanceRequired = $isViewingBeforeAcceptanceRequired
			isPerDeviceAcceptanceRequired = $isPerDeviceAcceptanceRequired
			present = $present
			sourceConfig = $sourceConfig
		}
		
		"userReacceptRequiredFrequency", "termsExpiration", "files" | foreach {
			if ($PSBoundParameters.ContainsKey($_)) {			
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $PSBoundParameters[$_]
			}
		}

		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$componentName][$script:desiredConfiguration[$componentName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$componentName] += $object
		}		
	}
}
