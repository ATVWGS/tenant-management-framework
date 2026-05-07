function Register-TmfDeviceRegistrationPolicy {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "localAdminPassword")]
    [CmdletBinding()]
	Param (
        [Parameter(Mandatory)]
        [string] $displayName = "adminConsentRequestPolicy",
        [Parameter(Mandatory)]
        [string] $multiFactorAuthConfiguration,
        [Parameter(Mandatory)]
        [string] $userDeviceQuota,
        [Parameter(Mandatory)]
        [object] $azureADRegistration,
        [Parameter(Mandatory)]
        [object] $azureADJoin,
        [Parameter(Mandatory)]
        [object] $localAdminPassword,        
        [bool] $present = $true,
        [string] $sourceConfig = "<Custom>",
        [string] $sourceFile = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
    )

    begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "deviceRegistrationPolicy"
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
			multiFactorAuthConfiguration = $multiFactorAuthConfiguration
            userDeviceQuota = $userDeviceQuota
            azureADRegistration = $azureADRegistration
            localAdminPassword = $localAdminPassword
            present = $present
			sourceConfig = $sourceConfig
            sourceFile = $sourceFile
		}
        
        if ($azureADJoin.allowedToJoin."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership" -or $azureADJoin.localAdmins.registeringUsers."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {
            $tmpObj = @{}
            $tmpObj["isAdminConfigurable"] = $azureADJoin.isAdminConfigurable
            if ($azureADJoin.allowedToJoin."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {
                $tmpObj["allowedToJoin"] = @{}
                $tmpObj["allowedToJoin"]["@odata.type"] = "#microsoft.graph.enumeratedDeviceRegistrationMembership"
                if ($azureADJoin.allowedToJoin.users) {
                    $tmpObj["allowedToJoin"]["users"] = @()
                    foreach ($user in $azureADJoin.allowedToJoin.users) {$tmpObj["allowedToJoin"]["users"] += Resolve-User -InputReference $user}
                }
                else {
                    $tmpObj["allowedToJoin"]["users"] = @()
                }
                if ($azureADJoin.allowedToJoin.groups) {
                    $tmpObj["allowedToJoin"]["groups"] = @()
                    foreach ($group in $azureADJoin.allowedToJoin.groups) {$tmpObj["allowedToJoin"]["groups"] += Resolve-Group -InputReference $group -SearchInDesiredConfiguration}
                }
                else {
                    $tmpObj["allowedToJoin"]["groups"] = @()
                }
            }
            else {
                $tmpObj["allowedToJoin"] = $azureADJoin.allowedToJoin
            }
            if ($azureADJoin.localAdmins.registeringUsers."@odata.type" -eq "#microsoft.graph.enumeratedDeviceRegistrationMembership") {
                $tmpObj["localAdmins"] = @{}
                $tmpObj["localAdmins"]["enableGlobalAdmins"] = $azureADJoin.localAdmins.enableGlobalAdmins
                $tmpObj["localAdmins"]["registeringUsers"] = @{} 
                $tmpObj["localAdmins"]["registeringUsers"]["@odata.type"] = "#microsoft.graph.enumeratedDeviceRegistrationMembership"
                if ($azureADJoin.localAdmins.registeringUsers.users) {
                    $tmpObj["localAdmins"]["registeringUsers"]["users"] = @()
                    foreach ($user in $azureADJoin.localAdmins.registeringUsers.users) {$tmpObj["localAdmins"]["registeringUsers"]["users"] += Resolve-User -InputReference $user}
                }
                else {
                    $tmpObj["localAdmins"]["registeringUsers"]["users"] = @()
                }
                if ($azureADJoin.localAdmins.registeringUsers.groups) {
                    $tmpObj["localAdmins"]["registeringUsers"]["groups"] = @()
                    foreach ($group in $azureADJoin.localAdmins.registeringUsers.groups) {$tmpObj["localAdmins"]["registeringUsers"]["groups"] += Resolve-Group -InputReference $group -SearchInDesiredConfiguration}
                }
                else {
                    $tmpObj["localAdmins"]["registeringUsers"]["groups"] = @()
                }
            }
            else {
                $tmpObj["localAdmins"] = $azureADJoin.localAdmins
            }
            Add-Member -InputObject $object -MemberType NoteProperty -Name "azureADJoin" -Value $tmpObj
        }
        else {
            Add-Member -InputObject $object -MemberType NoteProperty -Name "azureADJoin" -Value $azureADJoin
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