function Register-TmfRoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'AzureAD')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [bool] $present,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [ValidateSet('active', 'eligible')]
        [string] $type,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string] $principalReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [ValidateSet('group', 'user', 'servicePrincipal')]
        [string] $principalType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $subscriptionReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $scopeReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [ValidateSet('subscription', 'resourceGroup', 'resource')]
        [string] $scopeType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [string] $directoryScopeReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string] $groupReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [ValidateSet('directory', 'administrativeUnit', 'group')]
        [string] $directoryScopeType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [string] $roleReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [dateTime] $startDateTime,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [Parameter(Mandatory = $true, ParameterSetName = "AADGroup")]
        [ValidateSet('noExpiration', 'AfterDateTime', 'AfterDuration')]
        [string] $expirationType,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
        [dateTime] $endDateTime,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
        [string] $duration,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
        [string] $sourceConfig = "<Custom>",
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [Parameter(ParameterSetName = "AADGroup")]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

    begin {
        $resourceName = "roleAssignments"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}
        if ($subscriptionReference) {
            $assignmentScope = "AzureResources"
        }
        else {
            if ($groupReference) {
                $assignmentScope = "AADGroup"
            }
            else {
                $assignmentScope = "AzureAD"
            }            
        }
        foreach ($item in $script:desiredConfiguration[$resourceName]) {

            switch ($assignmentScope) {
                "AzureResources" {
                    if ($item.type -eq $type -and $item.principalReference -eq $principalReference -and $item.roleReference -eq $roleReference -and $item.scopeReference -eq $scopeReference) {
                        $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.type -eq $type -and $_.principalReference -eq $principalReference -and $_.roleReference -eq $roleReference -and $_.scopeReference -eq $scopeReference}
                    }
                }
                "AzureAD" {
                    if ($item.type -eq $type -and $item.principalReference -eq $principalReference -and $item.roleReference -eq $roleReference -and $item.directoryScopeReference -eq $directoryScopeReference) {
                        $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.type -eq $type -and $_.principalReference -eq $principalReference -and $_.roleReference -eq $roleReference -and $item.directoryScopeReference -eq $directoryScopeReference}
                    }
                }
                "AADGroup" {
                    if ($item.type -eq $type -and $item.principalReference -eq $principalReference -and $item.roleReference -eq $roleReference -and $item.groupReference -eq $groupReference) {
                        $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.type -eq $type -and $_.principalReference -eq $principalReference -and $_.roleReference -eq $roleReference -and $item.groupReference -eq $groupReference}
                    }
                }
            }
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) { return }		

        switch ($assignmentScope) {
            "AzureResources" {
                $object = [PSCustomObject] @{
                    present = $present
                    type = $type
                    principalReference = $principalReference
                    principalType = $principalType
                    subscriptionReference = $subscriptionReference
                    scopeReference = $scopeReference
                    scopeType = $scopeType
                    roleReference = $roleReference
                    startDateTime = $startDateTime
                    expirationType = $expirationType
                    sourceConfig = $sourceConfig
                }
        
                "endDateTime", "duration" | ForEach-Object {
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
            "AzureAD" {
                $object = [PSCustomObject] @{
                    present = $present
                    type = $type
                    principalReference = $principalReference
                    principalType = $principalType
                    roleReference = $roleReference
                    directoryScopeReference = $directoryScopeReference
                    directoryScopeType = $directoryScopeType
                    startDateTime = $startDateTime
                    expirationType = $expirationType
                    sourceConfig = $sourceConfig
                }
        
                "endDateTime", "duration" | ForEach-Object {
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
            "AADGroup" {
                $object = [PSCustomObject] @{
                    present = $present
                    type = $type
                    principalReference = $principalReference
                    principalType = $principalType
                    roleReference = $roleReference
                    groupReference = $groupReference
                    directoryScopeType = $directoryScopeType
                    startDateTime = $startDateTime
                    expirationType = $expirationType
                    sourceConfig = $sourceConfig
                }
        
                if ($roleReference -notin @("member","owner")) {
                    Write-PSFMessage -Level Error -String 'TMF.Register.UnsupportedPropertyValue' -StringValues $roleReference, "member, owner" -Tag 'failed' -FunctionName $Cmdlet.CommandRuntime
                    $ErrorObject = New-Object Management.Automation.ErrorRecord "The provided value for property '$roleReference' is not supported. Possible values are: member, owner", "1", 'InvalidData', $object
                    $cmdlet.ThrowTerminatingError($ErrorObject)
                }

                "endDateTime", "duration" | ForEach-Object {
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
    }
    end {}
}