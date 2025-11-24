function Resolve-SubscribedSku
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $Expand, # Return object { skuId, skuPartNumber, servicePlans }
		[switch] $DisplayName, # Return skuPartNumber
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {
		$InputReference = Resolve-String -Text $InputReference
	}
	process
	{			
		try {
            if (-Not $script:cache["allSubscribedSkus"]) {
				$script:cache["allSubscribedSkus"] = (Invoke-MgGraphRequest -Method GET -Uri "$script:graphBaseUrl/subscribedSkus").Value `
											| Select-Object @{n = "id"; e = {$_["id"]}}, @{n = "skuPartNumber"; e = {$_["skuPartNumber"]}},
                                                            @{n = "servicePlans"; e = {$_["servicePlans"]}}, @{n = "skuId"; e = {$_["skuId"]}}
			}

			if ($InputReference -match $script:guidRegex) { $sku = $script:cache["allSubscribedSkus"] | Where-Object { $_.skuId -eq $InputReference } | Select-Object -First 1 }
			else { $sku = $script:cache["allSubscribedSkus"] | Where-Object { $_.skuPartNumber -eq $InputReference } | Select-Object -First 1 }
			if (-Not $sku -and -Not $DontFailIfNotExisting) { throw "Cannot find subscribedSkus $InputReference" } elseif (-Not $sku -and $DontFailIfNotExisting) { return $InputReference }
			if ($sku.count -gt 1) { throw "Got multiple subscribedSkus for $InputReference" }
			if (-not $Expand) { if ($DisplayName) { return ($sku.skuPartNumber) } return $sku.skuId }
			return [pscustomobject]@{ skuId=$sku.skuId; skuPartNumber=$sku.skuPartNumber; servicePlans=$sku.servicePlans }
		}
		catch {
			Write-PSFMessage -Level Warning -Message ("Cannot resolve SubscribedSku resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
    