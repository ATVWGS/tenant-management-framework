function Register-TmfAdminConsentRequestPolicy {

    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]

    [CmdletBinding()]
	Param (
        [Parameter(Mandatory)]
        [string] $displayName = "adminConsentRequestPolicy",
        [Parameter(Mandatory)]
        [bool] $isEnabled,
        [Parameter(Mandatory)]
        [bool] $notifyReviewers,
        [Parameter(Mandatory)]
        [bool] $remindersEnabled,
        [Parameter(Mandatory)]
        [int] $requestDurationInDays,
        [object[]] $reviewers = @(),        
        [bool] $present = $true,
        [string] $sourceConfig = "<Custom>",
        [string] $sourceFile = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "adminConsentRequestPolicy"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}

    process { 
        if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{		
			displayName = $displayName
			isEnabled = $isEnabled
            notifyReviewers = $notifyReviewers
            remindersEnabled = $remindersEnabled
            requestDurationInDays = $requestDurationInDays
            present = $present
			sourceConfig = $sourceConfig
            sourceFile = $sourceFile
		}
        
        if ($reviewers) {
            Add-Member -InputObject $object -MemberType NoteProperty -Name "reviewers" -Value @($reviewers | ForEach-Object {
                $reference = $_.reference
                switch ($_.type) {
                    "singleUser" {
                        @{
                            "query" = "/v1.0/users/$(Resolve-User -InputReference $reference)"
                            "queryRoot" = $null
                            "queryType" = "MicrosoftGraph"
                        }
                    }
                    "groupMembers" {
                        @{
                            "query" = "/v1.0/groups/$(Resolve-Group -InputReference $reference)/transitiveMembers/microsoft.graph.user"
                            "queryRoot" = $null
                            "queryType" = "MicrosoftGraph"
                        }
                    }
                    "roleMembers" {
                        @{
                            "query" = "/beta/roleManagement/directory/roleAssignments?`$filter=roleDefinitionId eq '$(Resolve-DirectoryRoleDefinition -InputReference $reference)'"
                            "queryRoot" = $null
                            "queryType" = "MicrosoftGraph"
                        }
                    }
                }

            })
        }
        else {
            Add-Member -InputObject $object -MemberType NoteProperty -Name "reviewers" -Value @()
        }

        Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
    }

    end {}
}