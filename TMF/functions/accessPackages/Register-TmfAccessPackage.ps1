function Register-TmfAccessPackage
{
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
		[string] $description = "Access Package has been created with Tenant Management Framework",
		[bool] $isHidden = $false,
		[bool] $isRoleScopesVisible = $true,

		[Parameter(Mandatory = $true)]
		[string] $catalogDisplayName,
		[string] $catalogDescription = "Catalog has been created with Tenant Management Framework",
		[bool] $isExternallyVisible = $true,

		[Parameter(Mandatory = $true)]
		[string] $policyDisplayName,
		[string] $policyDescription,
		[bool] $canExtend = $false,
		[Parameter(Mandatory = $true)]
		[int] $durationInDays,

		[bool] $accessReviewIsEnabled = $false,
		[String] $accessReviewRecurrenceType = "monthly", # validation
		[String] $accessReviewReviewerType = "Reviewer",
		[int] $accessReviewDurationInDays = 14,
		[string[]] $accessReviewReviewer,

		[string] $requestorScopeType = "SpecificDirectorySubjects",
		[bool] $acceptRequests = $false,
		[string[]] $allowedRequestors,

		[bool] $isApprovalRequired = $true,
		[bool] $isApprovalRequiredForExtension = $true,
		[bool] $isRequestorJustificationRequire = $true,
		[string] $approvalMode = "SingleStage",
		[int] $approvalStageTimeOutInDays = 14,
		[bool] $isApproverJustificationRequired = $false,
		[bool] $isEscalationEnabled = $false,
		[bool] $escalationTimeInMinutes = "2880",
		[string[]] $primaryApprovers,
		[string[]] $escalationApprovers,
		[string[]] $questions,

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
				"isEnabled" = $accessReviewIsEnabled
				"recurrenceType" = $accessReviewRecurrenceType
				"reviewerType" = $accessReviewReviewerType
				"durationInDays" = $accessReviewDurationInDays
				"reviewers" = $accessReviewReviewer
				{
					#
				}
			"requestorSettings"= @{
				"scopeType"= $equestorScopeType
				"acceptRequests"= $equestorAcceptRequests
				"allowedRequestors"= $allowedRequestors
				{
					#
				}
			}
			"requestApprovalSettings"= @{
				"isApprovalRequired"= $isApprovalRequired
				"isApprovalRequiredForExtension"= $isApprovalRequiredForExtension
				"isRequestorJustificationRequired"= $isRequestorJustificationRequired
				"approvalMode"= $approvalMode
				"approvalStages"= @{
						"approvalStageTimeOutInDays"= $approvalStageTimeOutInDays
						"isApproverJustificationRequired"= $isApproverJustificationRequired
						"isEscalationEnabled"= $isEscalationEnabled
						"escalationTimeInMinutes"= $escalationTimeInMinutes
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

		@(
			"accessReviewReviewer", "allowedRequestors", "primaryApprovers", "escalationApprovers",
			"questions"
		) | foreach {
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
