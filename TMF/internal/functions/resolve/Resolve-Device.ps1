function Resolve-Device
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
			if ($InputReference -match $script:guidRegex) {
				$device = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/devices/{0}" -f $InputReference)).Id
			}
			else {
				$device = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/devices/?`$filter=displayName eq '{0}'" -f $InputReference)).Value.Id
			}

			if (-Not $device -and -Not $DontFailIfNotExisting) { throw "Cannot find device $InputReference" } 
			elseif (-Not $device -and $DontFailIfNotExisting) { return }

			if ($device.count -gt 1) { throw "Got multiple devices for $InputReference" }
			return $device
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "Device" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
