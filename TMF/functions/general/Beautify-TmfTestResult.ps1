function Beautify-TmfTestResult
{
	<#
		.SYNOPSIS
			Beautifies the returned output of the Test-TmfRESOURCE functions.

		.PARAMETER TestResult
			The input test result object.

		.PARAMETER FunctionName
			Name of the function which returned the output.

		.PARAMETER DoNotShowPropertyChanges
			Do not print property changes from the test result object.

		.EXAMPLE
			PS> Test-TmfGroup | Beautify-TmfTestResult
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object] $TestResult,
		[string] $FunctionName = "TMF",
		[switch] $DoNotShowPropertyChanges
	)
	
	process
	{
		Write-PSFMessage -Level Host -FunctionName $FunctionName -String "TMF.TestResult.BeautifySimple" -StringValues $TestResult.Tenant, $TestResult.ResourceName, $TestResult.ResourceType, $TestResult.ActionType, (Get-ActionColor -Action $TestResult.ActionType)
		if (!$DoNotShowPropertyChanges) {
			if ($TestResult.ActionType -eq "Update") {
				foreach ($change in $TestResult.Changes) {
					foreach ($action in $change.Actions.Keys) {						
						$value = $change.Actions[$action] | ConvertTo-Json -Compress -Depth 8
						Write-PSFMessage -Level Host -FunctionName $FunctionName -String "TMF.TestResult.BeautifyPropertyChange" -StringValues $TestResult.Tenant, $TestResult.ResourceName, $TestResult.ResourceType, $change.Property, $action, $value
					}
				}
			}
		}
	}
}
