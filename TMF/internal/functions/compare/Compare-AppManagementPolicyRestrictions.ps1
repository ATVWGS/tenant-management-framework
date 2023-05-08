function Compare-AppManagementPolicyRestrictions {
    Param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $ReferenceObject,
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable] $DifferenceObject,
        [System.Management.Automation.PSCmdlet]
        $Cmdlet = $PSCmdlet
    )

    begin {
        $propertiesToCompare = @("restrictionType","maxLifeTime","restrictForAppsCreatedAfterDateTime")
        $same = $true
    }

    process {
        foreach ($credentialProperty in @("passwordCredentials","keyCredentials")) {

            if ($ReferenceObject.ContainsKey($credentialProperty)) {
                if (-not ($DifferenceObject.ContainsKey($credentialProperty))) {
                    $same = $false
                }
                else {
                    if ($ReferenceObject.$credentialProperty) {
                        if (-not $DifferenceObject.$credentialProperty) {
                            $same = $false
                        }
                        else {
                            if (Compare-Object $ReferenceObject.$credentialProperty.restrictionType $DifferenceObject.$credentialProperty.restrictionType) {
                                $same = $false
                            }
                            else {
                                foreach ($item in $ReferenceObject.$credentialProperty) {
                                    foreach ($property in $propertiesToCompare) {
                                        if ($null -eq $item.$property) {
                                            if (-not ($null -eq ($DifferenceObject.$credentialProperty | Where-Object {$_.restrictionType -eq $item.restrictionType}).$property)) {
                                                $same = $false
                                            }
                                        }
                                        else {
                                            switch ($property) {
                                                "restrictForAppsCreatedAfterDateTime" {
                                                    if (([datetime]$item.$property).ToUniversalTime().ToString() -ne ($DifferenceObject.$credentialProperty | Where-Object {$_.restrictionType -eq $item.restrictionType}).$property.tostring()) {
                                                        $same = $false
                                                    }
                                                }
                                                default {
                                                    if ($item.$property -ne ($DifferenceObject.$credentialProperty | Where-Object {$_.restrictionType -eq $item.restrictionType}).$property) {
                                                        $same = $false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else {
                        if ($DifferenceObject.$credentialProperty) {
                            $same = $false
                        }
                    }
                }
            }
            else {
                if ($DifferenceObject.ContainsKey($credentialProperty)) {
                    $same = $false
                }
            }
        }
    }
    end {
        return $same
    }
}