function Register-TmfAccessPackage
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[Parameter(Mandatory = $true)]
		[string] $catalogDisplayName,

		
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
		$componentName = "accessPackages"
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

		$object = [PSCustomObject]@{
		"accessPackage"=[PSCustomObject]@{
			"catalogId" = Resolve-AccessPackageCatalog -AccesPackageCatalogReference $catalogDisplayName
			"displayName" = $displayName
			"description" = $description
			"isHidden" = $isHidden
			"isRoleScopesVisible" = $isRoleScopesVisible
		}
		"catalog"= [PSCustomObject]@{
			"displayName" = $catalogDisplayName
            "description" = $catalogDescription
            "isExternallyVisible" = $isExternallyVisible
		}
		"policy" =[PSCustomObject]@{
			"displayName" = $policyDisplayName
			"description"= $policyDescription
			"canExtend"= $canExtend
			"durationInDays"= $durationInDays
			"accessReviewSettings"= @{
				"isEnabled" = $true
				"recurrenceType" = "monthly"
				"reviewerType" = "Reviewers"
				"durationInDays" = 14
				"reviewers" = $result.DesiredConfiguration.policy.reviewers
			"requestorSettings"= @{
				"scopeType"= $result.DesiredConfiguration.policy.scopeType
				"acceptRequests"= $result.DesiredConfiguration.policy.acceptRequests
				"allowedRequestors"= $result.DesiredConfiguration.policy.requestorSettings.allowedRequestors
			}
			"requestApprovalSettings"= @{
				"isApprovalRequired"= $true
				"isApprovalRequiredForExtension"= $false
				"isRequestorJustificationRequired"= $true
				"approvalMode"= "SingleStage"
				"approvalStages"= @{
						"approvalStageTimeOutInDays"= 14
						"isApproverJustificationRequired"= $false
						"isEscalationEnabled"= $false
						"escalationTimeInMinutes"= 0
						"primaryApprovers"= @([PSCustomObject]@{
								"@odata.type"= $result.DesiredConfiguration.policy.primaryApprovers.odataType
								"isBackup"= $true
								"id"= $result.DesiredConfiguration.policy.primaryApprovers
								#Resolve-Group -GroupReference $result.DesiredConfiguration.requestorSettings.allowedRequestors
						})
						"escalationApprovers"= @([PSCustomObject]@{
							"@odata.type"= $result.DesiredConfiguration.policy.primaryApprovers.odataType
							"isBackup"= $true
							"id"= $result.DesiredConfiguration.policy.primaryApprovers
							#Resolve-Group -GroupReference $result.DesiredConfiguration.requestorSettings.allowedRequestors
						})
					}
				}
			"questions"= $questions
			}
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
