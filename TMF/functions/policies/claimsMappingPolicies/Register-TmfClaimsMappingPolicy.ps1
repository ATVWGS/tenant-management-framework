function Register-TmfClaimsMappingPolicy {
    [CmdletBinding()]
	Param (
		[string] $displayName,
        [Parameter(Mandatory = $true)]
        [string[]] $definition,
        [Parameter(Mandatory = $true)]
        [bool] $isOrganizationDefault,
        [string[]] $appliesTo,
        [bool] $present = $true,
        [string] $sourceConfig = "<Custom>",
        [string] $sourceFile = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $Cmdlet
		$resourceName = "claimsMappingPolicies"
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
            definition = $definition
            isOrganizationDefault = $isOrganizationDefault
            present = $present
			sourceConfig = $sourceConfig
            sourceFile = $sourceFile
		}

        if ($appliesTo) {
            $appliesToIds = @()
            foreach ($SPN in $appliesTo) {
                $appliesToIds += Resolve-ServicePrincipal -InputReference $SPN
            }
            Add-Member -InputObject $object -MemberType NoteProperty -Name appliesTo -Value $appliesToIds
        }
        else {
            Add-Member -InputObject $object -MemberType NoteProperty -Name appliesTo -Value @()
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