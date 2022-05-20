function Validate-AssignedLicense
{
	[CmdletBinding()]
    [OutputType([hashtable])]
	Param (
        [Parameter(Mandatory = $true)]
		[string] $skuId,
        [string[]] $disabledPlans,
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin
	{
		$sku = Resolve-SubscribedSku -InputReference $skuId -Cmdlet $Cmdlet		
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }

		$hashtable = @{
            skuId = $sku.skuId
        }

		Write-Verbose ($sku | ConvertTo-Json -Depth 8)

        $hashtable["disabledPlans"] = @($disabledPlans | ForEach-Object {
            $plan = $_
            $sku.servicePlans | Where-Object { $_.servicePlanId -eq $plan -or $_.servicePlanName -eq $plan } | Select-Object -ExpandProperty servicePlanId
        })
	}
	end
	{
		$hashtable
	}
}
