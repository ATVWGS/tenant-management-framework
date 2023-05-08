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
                        Write-Host ("$($reference.Key) Line 19")
                        $same = $false
                    }
                }
                elseif ($reference.Value.GetType().Name -eq "Hashtable") {
                    if ($DifferenceObject[$reference.Key]) {
                        if (-Not (Compare-Hashtable -ReferenceObject $reference.Value -DifferenceObject $DifferenceObject[$reference.Key])) {
                            Write-Host ("$($reference.Key) Line 26")
                            $same = $false
                        }
                    }
                    else {
                        Write-Host ("$($reference.Key) Line 31")
                        $same = $false
                    }
                }
                elseif ($reference.Value.GetType().Name -eq "Object[]") {
                    if (Compare-Object -ReferenceObject $reference.Value -DifferenceObject $DifferenceObject[$reference.Key]) {
                        Write-Host ("$($reference.Key) Line 37")
                        $same = $false
                    }
                }
                else {
                    if ($reference.Value -ne $DifferenceObject[$reference.Key]) {
                        Write-Host ("$($reference.Key) Line 43")
                        $same = $false
                    }
                }
            }
            else {
                if (-not ($null -eq $reference.Value)) {
                    Write-Host ("$($reference.Key) Line 50")
                    $same = $false
                }                
            }            
        }
    }
    end {
        return $same
    }
}