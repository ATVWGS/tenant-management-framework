function Register-TmfCustomAuthenticationExtension
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string] $description,
        [Parameter(Mandatory = $true)]
        [ValidateSet("#microsoft.graph.onPasswordSubmitCustomExtension","#microsoft.graph.onAttributeCollectionSubmitCustomExtension","#microsoft.graph.onAttributeCollectionStartCustomExtension","#microsoft.graph.onTokenIssuanceStartCustomExtension")]
		[string] ${@odata.type},
        [Parameter(Mandatory = $true)]
		[object] $authenticationConfiguration,
		[Parameter(Mandatory = $true)]
		[object] $endpointConfiguration,
		[object] $clientConfiguration,
		[object] $claimsForTokenConfiguration,
		[string[]] $oldNames,
		[bool] $present = $true,		
		[string] $sourceConfig = "<Custom>",
		[string] $sourceFile = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "customAuthenticationExtensions"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			displayName = $displayName
            description = $description
            "@odata.type" = ${@odata.type}
			authenticationConfiguration = $authenticationConfiguration
			endpointConfiguration = $endpointConfiguration
			present = $present
			sourceConfig = $sourceConfig
			sourceFile = $sourceFile
		}

		if ($PSBoundParameters.ContainsKey("clientConfiguration")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name clientConfiguration -Value $clientConfiguration
		}
		if ($PSBoundParameters.ContainsKey("claimsForTokenConfiguration")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name claimsForTokenConfiguration -Value $claimsForTokenConfiguration
		}
		if ($PSBoundParameters.ContainsKey("oldNames")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "oldNames" -Value @($oldNames | ForEach-Object {Resolve-String $_})
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
