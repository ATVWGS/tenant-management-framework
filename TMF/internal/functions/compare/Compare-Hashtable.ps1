function Compare-Hashtable {
    Param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $ReferenceObject,
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $DifferenceObject,
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    begin {
        $same = $true
    }
    process {
        foreach ($reference in $ReferenceObject.GetEnumerator()) {            
            if ($DifferenceObject.ContainsKey($reference.Key)) {     
                if ($null -eq $reference.Value) {
                    if ($null -eq $DifferenceObject[$reference.Key]) {
                        $same = $false
                    }
                }
                elseif ($reference.Value.GetType().Name -eq "Hashtable") {
                    if ($DifferenceObject[$reference.Key]) {
                        if (-Not (Compare-Hashtable -ReferenceObject $reference.Value -DifferenceObject $DifferenceObject[$reference.Key])) {
                            $same = $false
                        }
                    }
                    else {
                        $same = $false
                    }
                }
                elseif ($reference.Value.GetType() -in @("System.Object[]", "string[]")) {
                    if (Compare-Object -ReferenceObject $reference.Value -DifferenceObject $DifferenceObject[$reference.Key]) {
                        $same = $false
                    }
                }
                else {
                    if ($reference.Value -ne $DifferenceObject[$reference.Key]) {
                        $same = $false
                    }
                }
            }
            else {
                $same = $false
            }            
        }
    }
    end {
        return $same
    }
}