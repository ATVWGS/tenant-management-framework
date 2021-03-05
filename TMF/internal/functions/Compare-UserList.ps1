function Compare-UserList
{
	[CmdletBinding()]
	Param (
		[string[]] $ReferenceList,
		[string[]] $DifferenceList,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		#Test-GraphConnection -Cmdlet $PSCmdlet
	}
	process
	{
		if ($DifferenceList.count -eq 0 -and $ReferenceList.Count -eq 0) {
			return
		}

		$DifferenceList = @($DifferenceList | foreach { Resolve-User -UserReference $_ -Cmdlet $Cmdlet } | select -ExpandProperty Id)
		$compare = Compare-Object -ReferenceObject $ReferenceList -DifferenceObject $DifferenceList
		if (-Not $compare) { return }

		$result = @{}
		if ($compare.SideIndicator -contains "=>") {
			$result["Add"] = ($compare | ? {$_.SideIndicator -eq "=>"}).InputObject
		}
		if ($compare.SideIndicator -contains "<=") {
			$result["Remove"] = ($compare | ? {$_.SideIndicator -eq "<="}).InputObject
		}
		return $result
	}
}
