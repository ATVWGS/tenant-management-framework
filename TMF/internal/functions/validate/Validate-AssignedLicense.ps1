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

		if ($sku.servicePlans.GetType().Name -eq "Object[]") {
			$servicePlans = $sku.servicePlans
		}
		else {
			$servicePlans = $sku.servicePlans.value
		}

        $hashtable["disabledPlans"] = @($disabledPlans | ForEach-Object {
            $plan = $_
            ($servicePlans | Where-Object { $_.servicePlanId -eq $plan -or $_.servicePlanName -eq $plan }).servicePlanId
        })
	}
	end
	{
		$hashtable
	}
}
