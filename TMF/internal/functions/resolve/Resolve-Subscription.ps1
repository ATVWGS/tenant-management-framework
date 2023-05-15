function Resolve-Subscription {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
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
            $subscriptionId = ((Invoke-RestMethod -Method GET -uri "$($script:apiBaseUrl)subscriptions?$($script:apiVersion)" -Headers @{"Authorization"="Bearer $($token)"}).value | Where-Object {$_.displayname -eq $InputReference}).id
            if ($subscriptionId.count -ne 1) {throw "Can not find subscription $($InputReference)"}
            return $subscriptionId
        }
        catch {
            Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Subscription" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
        }
    }
}