function Register-TmfDirectoryRole {
    [CmdletBinding()]
	Param (
		[bool] $present = $true,	
		[string] $displayName,
        [object[]] $members,
			
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "directoryRoles"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}

    process {
        if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			present = $present
			displayName = $displayName
        }

		$memberIDs = @()
		if ($members) {
			foreach ($member in $members) {
				switch ($member.type) {
					"group" {
						$memberID = Resolve-Group -InputReference $member.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
						$memberIDs += $memberID
					}
					"singleUser" {
						$memberID = Resolve-User -InputReference $member.reference -SearchInDesiredConfiguration -Cmdlet $PSCmdlet
						$memberIDs += $memberID
					}
				}
			}
		}

		$roleId = Resolve-DirectoryRole -InputReference $displayName -SearchInDesiredConfiguration -DontFailIfNotExisting -Cmdlet $PSCmdlet

        Add-Member -InputObject $object -MemberType NoteProperty -Name "roleId" -Value $roleId
		Add-Member -InputObject $object -MemberType NoteProperty -Name "memberIDs" -Value $memberIDs
        Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name };

        if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
    }

    end {}
}