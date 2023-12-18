function Register-TmfAuthenticationContextClassReference
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $displayName,
        [Parameter(Mandatory = $true)]
        [ValidateSet("c1","c2","c3","c4","c5","c6","c7","c8","c9","c10","c11","c12","c13","c14","c15","c16","c17","c18","c19","c20","c21","c22","c23","c24","c25")]
		[string] $id,
		[string] $description,
        [Parameter(Mandatory = $true)]
		[bool] $isAvailable,
		[bool] $present = $true,		
		[string] $sourceConfig = "<Custom>",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$resourceName = "authenticationContextClassReferences"
		if (!$script:desiredConfiguration[$resourceName]) {
			$script:desiredConfiguration[$resourceName] = @()
		}

		if ($script:desiredConfiguration[$resourceName].displayName -contains $displayName) {			
			$alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object {$_.displayName -eq $displayName}
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

		$object = [PSCustomObject] @{
			displayName = $displayName
            id = $id
            isAvailable = $isAvailable
			present = $present
			sourceConfig = $sourceConfig
		}

		if ($PSBoundParameters.ContainsKey("description")) {
			Add-Member -InputObject $object -MemberType NoteProperty -Name "description" -Value $description
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
