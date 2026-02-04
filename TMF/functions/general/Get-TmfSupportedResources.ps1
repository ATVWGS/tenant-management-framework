function Get-TmfSupportedResources
{
	<#
		.SYNOPSIS
			Returns supported resources including weight.
	#>
	[CmdletBinding()]
	Param ()
	
	process
	{

        $supportedResourcesExport = @()
        $resourceNames = ($script:supportedResources).GetEnumerator().Name | Where-Object {$_ -notin @("stringMappings","roleManagementPolicyRuleTemplates")}

        foreach ($resourceName in $resourceNames) {
            $supportedResourcesExport += 
                if (($script:supportedResources)[$resourceName].parentType) {
                    [PSCustomObject]@{
                        Name = $resourceName
                        weight = ($script:supportedResources)[$resourceName].weight
                        ExportFunction = ($script:supportedResources)[$resourceName].ExportFunction.Name
                        InvokeFunction = ($script:supportedResources)[$resourceName].InvokeFunction.Name
                        TestFunction = ($script:supportedResources)[$resourceName].TestFunction.Name
                        parentType = ($script:supportedResources)[$resourceName].parentType
                    }
                }
                else {
                    [PSCustomObject]@{
                        Name = $resourceName
                        weight = ($script:supportedResources)[$resourceName].weight
                        ExportFunction = ($script:supportedResources)[$resourceName].ExportFunction.Name
                        InvokeFunction = ($script:supportedResources)[$resourceName].InvokeFunction.Name
                        TestFunction = ($script:supportedResources)[$resourceName].TestFunction.Name
                    }
                }
        }
		return $supportedResourcesExport
	}
}
