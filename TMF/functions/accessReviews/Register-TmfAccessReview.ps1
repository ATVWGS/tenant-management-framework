function Register-TmfAccessReview
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[object] $scope,
		[object[]] $reviewers,
		[object[]] $fallbackReviewers,
		[object] $settings,
		[bool] $present = $true,
		[string] $sourceConfig = "<Custom>",
		[string] $sourceFile = "<Custom>",
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
			sourceConfig = $sourceConfig
			sourceFile = $sourceFile
			reviewers = @()
			fallbackReviewers = @()
		}
		
		"scope", "reviewers", "fallbackReviewers", "settings" | ForEach-Object {
			if ($PSBoundParameters.ContainsKey($_)) {
				if ($script:supportedResources[$resourceName]["validateFunctions"].ContainsKey($_)) {
					
					switch ($_) {
						"reviewers" {
							$reviewers = $PSBoundParameters[$_]
							$property = "reviewers"
							for ($i=0; $i -lt $reviewers.count;$i++) {
								$validated = $PSBoundParameters[$property][$i] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$property].Parameters.Keys)
								$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$property] @validated -Cmdlet $Cmdlet
								$object.reviewers += $validated
							}
						}
						"fallbackReviewers" {
							$fallbackReviewers = $PSBoundParameters[$_]
							$property = "fallbackReviewers"
							Write-PSFMessage -Level Verbose -Message "FallbackReviewers: $fallbackReviewers"
							if ($fallbackReviewers -notlike "") {
								for ($i=0; $i -lt $fallbackReviewers.count;$i++) {
									$validated = $PSBoundParameters[$property][$i] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$property].Parameters.Keys)
									$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$property] @validated -Cmdlet $Cmdlet
									$object.fallbackReviewers += $validated
								}
							}							
						}
						"scope" {
							if ($scope.subScope) {
								$property = "scope"
								switch ($scope.subScope) {
									"servicePrincipals" {
										$validated = $PSBoundParameters[$property] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$property].Parameters.Keys)
										$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$property] @validated -Cmdlet $Cmdlet
										Add-Member -InputObject $object -MemberType NoteProperty -Name $property -Value $validated
									}
									"users_groups" {
										$validated = $PSBoundParameters[$property] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$property].Parameters.Keys)
										$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$property] @validated -Cmdlet $Cmdlet
										$objectscope = @{									
															"@odata.type"="#microsoft.graph.principalResourceMembershipsScope"
															"principalScopes"=@()
															"resourceScopes"=@()
										}
										Add-Member -InputObject $object -MemberType NoteProperty -Name $property -Value $objectscope
										$object.$property.principalScopes += $validated
									}
								}
							}
							else {
								if ($scope.reference) {
									$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$_].Parameters.Keys)
									$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$_] @validated -Cmdlet $Cmdlet
								}
								else {
									$validated = $PSBoundParameters[$_]
								}								
								Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
							}
						}
						default {
							$validated = $PSBoundParameters[$_] | ConvertTo-PSFHashtable -Include $($script:supportedResources[$resourceName]["validateFunctions"][$_].Parameters.Keys)
							$validated = & $script:supportedResources[$resourceName]["validateFunctions"][$_] @validated -Cmdlet $Cmdlet
							Add-Member -InputObject $object -MemberType NoteProperty -Name $_ -Value $validated
						}
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
