function Resolve-Subscription {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $Expand, # Return object { id, displayName }
		[switch] $DisplayName,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)

    begin {
		$InputReference = Resolve-String -Text $InputReference
        $token = (Get-AzAccessToken -ResourceUrl $script:apiBaseUrl).Token
	}
	process
	{			
		try {
			$subs = (Invoke-RestMethod -Method GET -uri "$($script:apiBaseUrl)subscriptions?$($script:apiVersion)" -Headers @{"Authorization"="Bearer $($token)"}).value
			$match = if ($InputReference -match $script:guidRegex) { $subs | Where-Object { $_.subscriptionId -eq $InputReference } | Select-Object -First 1 } else { $subs | Where-Object { $_.displayName -eq $InputReference } | Select-Object -First 1 }
			if (-not $match) { throw "Can not find subscription $InputReference" }
			if (-not $Expand) { if ($DisplayName) { return ($match.displayName) } return $match.id }
			return [pscustomobject]@{ id=$match.id; displayName=$match.displayName; subscriptionId=$match.subscriptionId }
        }
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve Subscription resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
		}
    }
}