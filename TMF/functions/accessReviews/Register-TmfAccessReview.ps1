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
		Test-GraphConnection -Cmdlet $Cmdlet
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
			reviewers = @()
		}
		
		"scope", "reviewers", "settings" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				if ($script:supportedResources[$resourceName]["validateFunctions"].ContainsKey($_)) {
					if ($_ -eq "reviewers") {
						$reviewers = $PSBoundParameters[$_]
						$property = "reviewers"
						for ($i=0; $i -lt $reviewers.count;$i++) {
							$validated = $PSBoundParameters[$property][$i] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$property].Parameters.Keys)
							$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$property] @validated -Cmdlet $Cmdlet
							$object.reviewers += $validated
						}
					}
					else {
						$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$_].Parameters.Keys)
						$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$_] @validated -Cmdlet $Cmdlet
						Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
					}
				}
				else {
					$validated = $PSBoundParameters[$_]
					Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
				}
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
