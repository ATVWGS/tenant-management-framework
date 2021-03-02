function Compare-UserList
{
	[CmdletBinding()]
	Param (
		[array] $ReferenceList,
		[array] $DifferenceList 
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
	}
	process
	{		
		$DifferenceList = $DifferenceList | foreach {
			if ($_ -match $guidRegex) {
				Get-MgUser -UserId $_
			}
			else {
				Get-MgUser -Filter "userPrincipalName eq '$_'"
			}
		} | select -ExpandProperty Id
		
		$compare = Compare-Object -ReferenceObject $ReferenceList -DifferenceObject $DifferenceList
		return @{
			"Add" = ($compare | ? {$_.SideIndicator -eq "=>"}).InputObject
			"Remove" = ($compare | ? {$_.SideIndicator -eq "<="}).InputObject
		}
	}
}
