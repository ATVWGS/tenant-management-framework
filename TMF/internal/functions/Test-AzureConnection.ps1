function Test-AzureConnection
{
	[CmdletBinding()]
	Param (
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)	
	
	process
	{
		if (Get-AzContext) { return	}

		Write-PSFMessage -Level Error -String 'Test-AzureConnection.Failed' -FunctionName $cmdlet.CommandRuntime
		
		$exception = New-Object System.Data.DataException("No Azure connection!")
		$errorID = 'NotConnected'
		$category = [System.Management.Automation.ErrorCategory]::NotSpecified
		$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
		$cmdlet.ThrowTerminatingError($recordObject)				
	}
}