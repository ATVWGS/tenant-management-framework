function Register-TmfAccessPackage
{
	[CmdletBinding(DefaultParameterSetName = 'IPRanges')]
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
		[string[]] $accessReviewer,

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
		[int] $escalationTimeInMinutes = 2880,
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
		$resourceName = "accessPackages"
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

		$object = [PSCustomObject]@{
		
		displayName = $displayName
		description = $description
		isHidden = $isHidden
		isRoleScopesVisible = $isRoleScopesVisible
		
		catalogDisplayName = $catalogDisplayName
        catalogDescription = $catalogDescription
        isExternallyVisible = $isExternallyVisible
		
		policyDisplayName = $policyDisplayName
		policyDescription = $policyDescription
		canExtend = $canExtend
		durationInDays = $durationInDays
		accessRevieIsEnabled = $accwessRevieIsEnabled
		accessReviewRecurrenceType = $accessReviewRecurrenceType
		
		accessReviewReviewerType = $accessReviewReviewerType
		accessReviewDurationInDays = $accessReviewDurationInDays


		requestorScopeType = $requestorScopeType
		requestorAcceptRequests = $requestorAcceptRequests


		isApprovalRequired = $isApprovalRequired
		isApprovalRequiredForExtension = $isApprovalRequiredForExtension
		isRequestorJustificationRequired = $isRequestorJustificationRequired
		approvalMode = $approvalMode
		approvalStageTimeOutInDays = $approvalStageTimeOutInDays
		isApproverJustificationRequired = $isApproverJustificationRequired
		isEscalationEnabled = $isEscalationEnabled
		escalationTimeInMinutes = $escalationTimeInMinutes



		}

		@(
			"accessReviewer", "allowedRequestors", "primaryApprovers", "escalationApprovers",
			"questions"
		) | foreach {
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
		
		write-host $script:desiredConfiguration[$resourceName]
	}
}
