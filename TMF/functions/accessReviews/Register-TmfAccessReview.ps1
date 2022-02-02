function Register-TmfAccessReview
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[object] $scope,
		[object[]] $reviewers,
		[object] $settings,
		[bool] $present = $true,		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "accessReviews"
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
			present = $present
		}
		
		"scope", "reviewers", "settings" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				if ($script:validateFunctionMapping.ContainsKey($_)) {
					$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:validateFunctionMapping[$_].Parameters.Keys)
					$validated = & $script:validateFunctionMapping[$_] @validated -Cmdlet $Cmdlet
				}
				else {
					$validated = $PSBoundParameters[$_]
				}
				Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
			}			
		}

		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name };

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}		
	}
}
