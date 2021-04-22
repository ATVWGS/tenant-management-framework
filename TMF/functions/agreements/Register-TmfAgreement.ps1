function Register-TmfAgreement
{
	[CmdletBinding()]
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
		$resourceName = "agreements"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | ? {$_.displayName -eq $displayName}
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
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}		
	}
}
