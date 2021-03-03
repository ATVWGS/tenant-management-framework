function Compare-UserList
{
	[CmdletBinding()]
	Param (
		[string] $Target = "<undefined>",
		[array] $ReferenceList,
		[array] $DifferenceList,
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet		
	}
	process
	{		
		$DifferenceList = $DifferenceList | foreach { Resolve-User -UserReference $_ -Cmdlet $Cmdlet } | select -ExpandProperty Id		
		$compare = Compare-Object -ReferenceObject $ReferenceList -DifferenceObject $DifferenceList
		if (!$compare) { return }
		return @{
			"Add" = ($compare | ? {$_.SideIndicator -eq "=>"}).InputObject
			"Remove" = ($compare | ? {$_.SideIndicator -eq "<="}).InputObject
		}
	}
}
