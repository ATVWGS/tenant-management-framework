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
                    if (-not ($null -eq $DifferenceObject[$reference.Key])) {
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
                        if ($reference.Key -eq "guestOrExternalUserTypes") {
                            if (-not ($DifferenceObject[$reference.Key])) {
                                $same = $false
                            }
                            else {
                                $referenceSplit = $reference.Value.split(",")
                                $differenceSplit = $DifferenceObject[$reference.Key].Split(",")

                                if (Compare-Object -ReferenceObject $referenceSplit -DifferenceObject $differenceSplit) {
                                    $same = $false
                                }
                            }                            
                        }
                        else {
                            $same = $false
                        }                        
                    }
                }
            }
            else {
                if (-not ($null -eq $reference.Value)) {
                    $same = $false
                }                
            }            
        }
    }
    end {
        return $same
    }
}