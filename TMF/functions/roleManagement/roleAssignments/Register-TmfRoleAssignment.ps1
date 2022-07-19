function Register-TmfRoleAssignment {
    [CmdletBinding(DefaultParameterSetName = 'AzureAD')]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [bool] $present,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [ValidateSet('active', 'eligible')]
        [string] $type,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $principalReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [ValidateSet('group', 'user', 'servicePrincipal')]
        [string] $principalType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $subscriptionReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $scopeReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [ValidateSet('subscription', 'resourceGroup')]
        [string] $scopeType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [string] $directoryScopeReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [ValidateSet('directory', 'administrativeUnit')]
        [string] $directoryScopeType,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [string] $roleReference,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [dateTime] $startDateTime,
        [Parameter(Mandatory = $true, ParameterSetName = "AzureAD")]
        [Parameter(Mandatory = $true, ParameterSetName = "AzureResources")]
        [ValidateSet('noExpiration', 'AfterDateTime', 'AfterDuration')]
        [string] $expirationType,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [dateTime] $endDateTime,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [string] $duration,
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
        [string] $sourceConfig = "<Custom>",
        [Parameter(ParameterSetName = "AzureAD")]
        [Parameter(ParameterSetName = "AzureResources")]
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
            $assignmentScope = "AzureAD"
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
        }
    }
    end {}
}