function Resolve-ResourceGroup {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,
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
            $resourceGroupId = (Invoke-RestMethod -Method GET -uri "$($script:apiBaseUrl)$($SubscriptionId.trimStart("/"))/resourcegroups/$($InputReference)?api-version=2022-01-01" -Headers @{"Authorization"="Bearer $($token)"}).id
            return $resourceGroupId
        }
        catch {
            Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Resource Group" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
        }
    }
}