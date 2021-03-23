function Compare-GroupList
{
	[CmdletBinding()]
	Param (
		[string[]] $ReferenceList,
		[string[]] $DifferenceList,
		[switch] $ReturnSetAction,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		Test-GraphConnection -Cmdlet $PSCmdlet
	}
	process
	{
		if ($DifferenceList.count -eq 0 -and $ReferenceList.Count -eq 0) {
			return
		}

		$DifferenceList = @($DifferenceList | foreach { (Resolve-Group -GroupReference $_ -Cmdlet $Cmdlet)["id"] })
		$compare = Compare-Object -ReferenceObject $ReferenceList -DifferenceObject $DifferenceList
		if (-Not $compare) { return }

		$result = @{}
		if ($compare.SideIndicator -contains "=>" -and -not $ReturnSetAction) {
			$result["Add"] = ($compare | ? {$_.SideIndicator -eq "=>"}).InputObject
		}
		if ($compare.SideIndicator -contains "<=" -and -not $ReturnSetAction) {
			$result["Remove"] = ($compare | ? {$_.SideIndicator -eq "<="}).InputObject
		}
		if ($ReturnSetAction) {
			$result["Set"] = $DifferenceList
		}
		return $result
	}
}
