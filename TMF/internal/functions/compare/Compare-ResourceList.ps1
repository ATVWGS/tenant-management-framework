function Compare-ResourceList
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
		if (-Not $DifferenceList) {$DifferenceList = @()}
		if (-Not $ReferenceList) {$ReferenceList = @()}

		if ($DifferenceList.count -eq 0 -and $ReferenceList.Count -eq 0) {
			return
		}		
		
		$compare = Compare-Object -ReferenceObject $ReferenceList -DifferenceObject $DifferenceList				
		if (-Not $compare) { return }

		$result = @{}
		if ($compare.SideIndicator -contains "=>" -and -not $ReturnSetAction) {
			$result["Add"] = ($compare | Where-Object {$_.SideIndicator -eq "=>"}).InputObject
		}
		if ($compare.SideIndicator -contains "<=" -and -not $ReturnSetAction) {
			$result["Remove"] = ($compare | Where-Object {$_.SideIndicator -eq "<="}).InputObject
		}
		if ($ReturnSetAction) {
			$result["Set"] = @($DifferenceList)
		}
		return $result
	}
}
