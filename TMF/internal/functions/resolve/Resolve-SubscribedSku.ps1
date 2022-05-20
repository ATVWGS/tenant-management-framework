function Resolve-SubscribedSku
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
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

			if ($InputReference -match $script:guidRegex) {
				$sku = $script:cache["allSubscribedSkus"] | Where-Object { $_.skuId -eq $InputReference } | Select-Object skuId, servicePlans
 			}
			else {
				$sku = $script:cache["allSubscribedSkus"] | Where-Object { $_.skuPartNumber -eq $InputReference } | Select-Object skuId, servicePlans
			}

			if (-Not $sku -and -Not $DontFailIfNotExisting) { throw "Cannot find subscribedSkus $InputReference" } 
			elseif (-Not $sku -and $DontFailIfNotExisting) { return }

			if ($sku.count -gt 1) { throw "Got multiple subscribedSkus for $InputReference" }
			return $sku
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "SubscribedSku" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
    