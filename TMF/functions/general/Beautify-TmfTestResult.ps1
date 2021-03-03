function Beautify-TmfTestResult
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[object] $TestResult,
		[string] $FunctionName = "Tenant Management Framework",
		[switch] $DoNotShowPropertyChanges
	)
	
	process
	{
		Write-PSFMessage -Level Host -FunctionName $FunctionName -String "TMF.TestResult.BeautifySimple" -StringValues $TestResult.Tenant, $TestResult.ResourceName, $TestResult.ResourceType, $TestResult.ActionType, (Get-ActionColor -Action $TestResult.ActionType)
		if (!$DoNotShowPropertyChanges) {
			if ($TestResult.ActionType -eq "Update") {
				foreach ($change in $TestResult.Changes) {
					foreach ($action in $change.Actions.Keys) {
						Write-PSFMessage -Level Host -FunctionName $FunctionName -String "TMF.TestResult.BeautifyPropertyChange" -StringValues $TestResult.Tenant, $TestResult.ResourceName, $TestResult.ResourceType, $change.Property, $action, ($change.Actions.$action -join ", ")
					}
				}
			}
		}
	}
}
