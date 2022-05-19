function Compare-AssignedLicenses
{
	[CmdletBinding()]
    [OutputType([object[]])]
	Param (
		[object[]] $ReferenceList,
		[object[]] $DifferenceList,
		[switch] $ReturnSetAction,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
        if (-Not $DifferenceList) {$DifferenceList = @()}
		if (-Not $ReferenceList) {$ReferenceList = @()}
    }
	process
	{
		$compare = Compare-Object -ReferenceObject $ReferenceList -DifferenceObject $DifferenceList -Property skuId -IncludeEqual
		if (-Not $compare) { return }

		$result = @{
            Add = @()
            Remove = @()
        }

        $compare | Foreach-Object {
            $skuId = $_.skuId
            switch ($_.SideIndicator) {
                "=>" {
                    $result["Add"] += $DifferenceList | Where-Object {$_.skuId -eq $skuId}
                }
                "==" {
                    $refPlans = @($ReferenceList | Where-Object {$_.skuId -eq $skuId} | Select-Object -ExpandProperty disabledPlans)
                    $difPlans = @($DifferenceList | Where-Object {$_.skuId -eq $skuId} | Select-Object -ExpandProperty disabledPlans)
                    if (Compare-Object -ReferenceObject $refPlans -DifferenceObject $difPlans) {
                        $result["Add"] += $DifferenceList | Where-Object {$_.skuId -eq $skuId}
                    }
                }
                "<=" {
                    $result["Remove"] += $skuId
                }
            }
        }

        "Add", "Remove" | ForEach-Object {
            if ($result[$_].Count -eq 0) {
                $result.Remove($_)
            }
        }
	}
    end {
        if (-Not $result -or $result.Keys.Count -eq 0) {
            return
        }
        return $result
    }
}