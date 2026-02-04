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
        $resourceNames = ($script:supportedResources).GetEnumerator().Name

        foreach ($resourceName in $resourceNames) {
            $supportedResourcesExport += [PSCustomObject]@{
                Name = $resourceName
                weight = ($script:supportedResources)[$resourceName].weight
                ExportFunction = ($script:supportedResources)[$resourceName].ExportFunction.Name
                InvokeFunction = ($script:supportedResources)[$resourceName].InvokeFunction.Name
                TestFunction = ($script:supportedResources)[$resourceName].TestFunction.Name
            }
        }
		return $supportedResourcesExport
	}
}
