function Compare-PolicyProperties {
    param (
        [Parameter(Mandatory = $true)]
        [object[]] $ReferenceObject,
        [Parameter(Mandatory = $true)]
        [object[]] $DifferenceObject,
        [Parameter(Mandatory = $true)]
        [string] $assignmentScope,
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    $same = $true

    switch ($assignmentScope) {
        "AzureAD" {
            $CompareObject = @()
            $DifferenceObject.id | Select-Object -Unique | ForEach-Object {
                $ruleId = $_
                if (($DifferenceObject.id | Where-Object {$_ -eq $ruleId}).count -gt 1) {
                    $CompareObject += ($DifferenceObject | Where-Object {$_.id -eq $ruleId})[-1]
                }
                else {
                    $CompareObject += $DifferenceObject | Where-Object {$_.id -eq $ruleId}
                }
            }
        }
        "AzureResources" {
            $CompareObject = $DifferenceObject
        }
    }
    

    foreach ($itemSet in $ReferenceObject) {
        $itemSetProperties = ($itemSet | Get-Member -MemberType NoteProperty).Name
        $compareProperties = $CompareObject | Where-Object {$_.id -eq $itemSet.id}

        foreach ($property in $itemSetProperties) {
            if ($null -ne $itemSet.$property) {
                if ($itemSet.$property.GetType().Name -in @("PSCustomObject","Object[]","System.Object[]")) {
                    if ($itemSet.$property -and $compareProperties.$property) {
                        if (-not (Compare-PolicyProperties -ReferenceObject $itemSet.$property -DifferenceObject $compareProperties.$property -assignmentScope $assignmentScope)) {
                            $same = $false
                        }
                    }
                    else {
                        if (($itemSet.$property -and (-not($compareProperties.$property))) -or ((-not($itemSet.$property) -and $compareProperties.$property))) {
                            $same = $false
                        }
                    }
                }
                else {
                    if ($itemSet.$property -ne $compareProperties.$property) {
                        $same = $false
                    }
                }
            }
        }
    }
    foreach ($itemSet in $CompareObject) {
        $itemSetProperties = ($itemSet | Get-Member -MemberType NoteProperty).Name
        $compareProperties = $ReferenceObject | Where-Object {$_.id -eq $itemSet.id}

        foreach ($property in $itemSetProperties) {

            if ($null -ne $itemSet.$property) {
                if ($itemSet.$property.GetType().Name -in @("PSCustomObject","Object[]","System.Object[]")) {
                    if ($itemSet.$property -and $compareProperties.$property) {
                        if (-not (Compare-PolicyProperties -ReferenceObject $itemSet.$property -DifferenceObject $compareProperties.$property -assignmentScope $assignmentScope)) {
                            $same = $false
                        }
                    }
                    else {
                        if (($itemSet.$property -and (-not($compareProperties.$property))) -or ((-not($itemSet.$property) -and $compareProperties.$property))) {
                            $same = $false
                        }
                    }
                }
                else {
                    if ($itemSet.$property -ne $compareProperties.$property) {
                        $same = $false
                    }
                }
            }
            else {
                if ($null -ne $compareProperties.$property) {
                    $same = $false
                }
            }
        }
    }
    return $same
}