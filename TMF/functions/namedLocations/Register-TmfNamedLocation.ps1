function Register-TmfNamedLocation
{
	[CmdletBinding(DefaultParameterSetName = 'IPRanges')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,

		[Parameter(Mandatory = $true)]
		[ValidateSet('countryNamedLocation', 'ipNamedLocation')]
		[string] $type = "ipNamedLocation",
		
		[Parameter(Mandatory = $true, ParameterSetName = "IPRanges")]
		[object[]] $ipRanges,
		[Parameter(ParameterSetName = "IPRanges")]
		[bool] $isTrusted = $false,
		[Parameter(Mandatory = $true, ParameterSetName = "Country")]
		[string[]] $countriesAndRegions,
		[Parameter(ParameterSetName = "Country")]
		[bool] $includeUnknownCountriesAndRegions = $false,

		[bool] $present = $true,		

		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$componentName = "namedLocations"

		if ($script:desiredConfiguration[$componentName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$componentName] | ? {$_.displayName -eq $displayName}
			if ($alreadyLoaded.sourceConfig -ne $sourceConfig) {
				Stop-PSFFunction -String "TMF.RegisterComponent.AlreadyLoaded" -StringValues "named location", $displayName, $alreadyLoaded.sourceConfig
				return
			}
		}

		try {
			if (
				($type -eq "ipNamedLocation" -and -not $PSBoundParameters.ContainsKey('ipRanges')) -or
				($type -ne "ipNamedLocation" -and $PSBoundParameters.ContainsKey('ipRanges'))
			) { throw "If you want to define a ipNamedLocation, you need to provide ipRanges and set the type to ipNamedLocation." }
			
			if (
				($type -eq "countryNamedLocation" -and -not $PSBoundParameters.ContainsKey('countriesAndRegions')) -or
				($type -ne "countryNamedLocation" -and $PSBoundParameters.ContainsKey('countriesAndRegions'))
			) { throw "If you want to define a countryNamedLocation, you need to provide countriesAndRegions and set the type to countryNamedLocation." }
		}
		catch {
			Write-PSFMessage -Level Error -String 'TMF.Register.PropertySetNotPossible' -StringValues $displayName, "Named Location" -Tag "failed" -ErrorRecord $_ -FunctionName $Cmdlet.CommandRuntime			
			$cmdlet.ThrowTerminatingError($_)
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			displayName = $displayName
			present = $present
			sourceConfig = $sourceConfig
		}

		switch ($type) {
			"ipNamedLocation" {
				Add-Member -InputObject $object -MemberType NoteProperty -Name "@odata.type" -Value "#microsoft.graph.ipNamedLocation"
				Add-Member -InputObject $object -MemberType NoteProperty -Name "ipRanges" -Value @($ipRanges)
				Add-Member -InputObject $object -MemberType NoteProperty -Name "isTrusted" -Value $isTrusted
			}
			"countryNamedLocation" {
				Add-Member -InputObject $object -MemberType NoteProperty -Name "@odata.type" -Value "#microsoft.graph.countryNamedLocation"
				Add-Member -InputObject $object -MemberType NoteProperty -Name "countriesAndRegions" -Value @($countriesAndRegions)
				Add-Member -InputObject $object -MemberType NoteProperty -Name "includeUnknownCountriesAndRegions" -Value $includeUnknownCountriesAndRegions
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
