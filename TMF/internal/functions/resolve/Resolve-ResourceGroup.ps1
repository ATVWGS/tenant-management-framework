function Resolve-ResourceGroup {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,
		[switch] $Expand, # Return object { id, name }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

    begin {
		$InputReference = Resolve-String -Text $InputReference
        $token = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
        if ($token.GetType().Name -eq "SecureString") {
			$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
			$token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
		}
	}
	process
	{			
		try {
			if ($InputReference -like '/subscriptions/*') { $resourceGroupId = $InputReference; $name = ($InputReference -split '/resourceGroups/')[1] -split '/' | Select-Object -First 1 }
			else { $resourceGroupId = (Invoke-RestMethod -Method GET -uri "$($script:apiBaseUrl)$($SubscriptionId.trimStart("/"))/resourcegroups/$($InputReference)?api-version=2022-01-01" -Headers @{"Authorization"="Bearer $($token)"}).id; $name = $InputReference }
			if (-not $Expand) { if ($DisplayName) { return $name } return $resourceGroupId }
			return [pscustomobject]@{ id=$resourceGroupId; displayName=$name }
        }
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve Resource Group resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
		}
    }
}