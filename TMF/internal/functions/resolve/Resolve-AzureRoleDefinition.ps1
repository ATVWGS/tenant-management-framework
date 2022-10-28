function Resolve-AzureRoleDefinition {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,
        [switch] $SearchInDesiredConfiguration,
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
            $role = (invoke-restmethod -Method GET -Uri ("$($script:apiBaseUrl)$($SubscriptionId)/providers/Microsoft.Authorization/roleDefinitions?`$filter=roleName eq '{0}'&api-version=2018-07-01" -f $InputReference) -Headers @{"Authorization"="Bearer $($token)"}).value.id
                            
            if (-Not $role -and $SearchInDesiredConfiguration) {
                if ($InputReference -in $script:desiredConfiguration["roleDefinitions"].roleName) {
                    $role = $InputReference
                }
                else {
                    throw "Can not find roleDefinition $($InputReference)"
                }
            }
            else {
                if (-not $role -and -not $SearchInDesiredConfiguration) {
                    throw "Can not find roleDefinition $($InputReference)"
                }
            }                
            
            return $role
        }
        catch {
            Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "RoleDefinition" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)
        }
    }
}