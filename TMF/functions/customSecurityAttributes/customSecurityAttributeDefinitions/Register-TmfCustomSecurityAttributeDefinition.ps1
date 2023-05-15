function Register-TmfCustomSecurityAttributeDefinition
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
        [Parameter(Mandatory = $true)]
		[string] $description,
        [Parameter(Mandatory = $true)]
		[string] $attributeSet,
        [Parameter(Mandatory = $true)]
		[bool] $isCollection,
        [Parameter(Mandatory = $true)]
		[bool] $isSearchable,
        [Parameter(Mandatory = $true)]
		[string] $status,
        [Parameter(Mandatory = $true)]
		[string] $type,
        [Parameter(Mandatory = $true)]
		[bool] $usePreDefinedValuesOnly,
        [object[]] $allowedValues,
		[bool] $present = $true,
		[string] $sourceConfig = "<Custom>",

		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "customSecurityAttributeDefinitions"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

        $name = $displayName
        $displayName = "$($attributeSet)_$($name)"

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}

	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject]@{		
			displayName = $displayName
			description = $description
            name = $name
			attributeSet = $attributeSet
            isCollection = $isCollection
            isSearchable = $isSearchable
            status = $status
            type = $type
            usePreDefinedValuesOnly = $usePreDefinedValuesOnly
			present = $present
			sourceConfig = $sourceConfig
		}
	
		Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }

        foreach ($allowedValue in $allowedValues) {
            $resource = $allowedValue | Add-Member -NotePropertyMembers @{sourceConfig = $sourceConfig; attributeId = $displayName; present = $present} -PassThru | ConvertTo-PSFHashtable -Include $((Get-Command Register-TmfCustomSecurityAttributeAllowedValue).Parameters.Keys)			
			Register-TmfCustomSecurityAttributeAllowedValue @resource -Cmdlet $PSCmdlet
        }

		if ($alreadyLoaded) {
			$script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object
		}
		else {
			$script:desiredConfiguration[$resourceName] += $object
		}
	}
}
