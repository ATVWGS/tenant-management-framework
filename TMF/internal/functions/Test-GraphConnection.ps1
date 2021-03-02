function Test-GraphConnection
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.PSCmdlet]
		$Cmdlet
	)	
	
	process
	{
		if (Get-MgContext) { return	}

		Write-PSFMessage -Level Error -String 'Test-GraphConnection.Failed' -FunctionName $cmdlet.CommandRuntime
		
		$exception = New-Object System.Data.DataException("No Microsoft Graph connection!")
		$errorID = 'NotConnected'
		$category = [System.Management.Automation.ErrorCategory]::NotSpecified
		$recordObject = New-Object System.Management.Automation.ErrorRecord($exception, $errorID, $category, $Cmdlet)
		$cmdlet.ThrowTerminatingError($recordObject)				
	}
}
