function Invoke-TmfUser {
    [CmdletBinding()] param(
        [string[]] $SpecificResources,
        [string[]] $SourceFile,
        [string[]] $SourceConfig,
        [switch] $Confirm = $false,
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        $resourceName = 'users'
        if (-not $script:desiredConfiguration[$resourceName]) {
            Stop-PSFFunction -String 'TMF.NoDefinitions' -StringValues 'User'; return
        }
        Test-GraphConnection -Cmdlet $Cmdlet
        $tenant = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/organization?`$select=displayname,id")).value
        if (($SpecificResources -and $SourceFile -and $SourceConfig) -or ($SpecificResources -and $SourceFile) -or ($SourceFile -and $SourceConfig)) {
            $exception = New-Object System.Data.DataException('Multiple filters are not supported. Use only one of SpecificResources, SourceFile or SourceConfig.')
            $recordObject = New-Object System.Management.Automation.ErrorRecord($exception, 'MultipleFiltersNotSupported', [System.Management.Automation.ErrorCategory]::NotSpecified, $Cmdlet)
            $Cmdlet.ThrowTerminatingError($recordObject)
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) {
            return
        }
        if (-not $Confirm) {
            Write-PSFMessage -Level Host -FunctionName 'Invoke-TmfUser' -String 'TMF.TenantInformation' -StringValues $tenant.displayName, $tenant.Id
            if ((Read-Host 'Is this the correct tenant? [y/n]') -notin @('y', 'Y')) {
                Write-PSFMessage -Level Error -String 'TMF.UserCanceled'; throw 'Connected to the wrong tenant.'
            }
        }
        if ($SpecificResources) {
            $testResults = Test-TmfUser -SpecificResources $SpecificResources -RawOutput -Cmdlet $Cmdlet
        } elseif ($SourceFile) {
            $testResults = Test-TmfUser -SourceFile $SourceFile -RawOutput -Cmdlet $Cmdlet
        } elseif ($SourceConfig) {
            $testResults = Test-TmfUser -SourceConfig $SourceConfig -RawOutput -Cmdlet $Cmdlet
        } else {
            $testResults = Test-TmfUser -RawOutput -Cmdlet $Cmdlet
        }
        foreach ($result in $testResults) {
            Beautify-TmfTestResult -TestResult $result -FunctionName $MyInvocation.MyCommand
            switch ($result.ActionType) {
                'Create' {
                    Write-PSFMessage -Level Warning -FunctionName 'Invoke-TmfUser' -Message "Create action for user $($result.ResourceName) is not implemented (skipped)."
                }
                'Delete' {
                    Write-PSFMessage -Level Warning -FunctionName 'Invoke-TmfUser' -Message "Delete action for user $($result.ResourceName) is not implemented (skipped)."
                }
                'Update' {
                    $patch = @{}
                    foreach ($change in $result.Changes) {
                        if ($change.Actions.Set) {
                            $patch[$change.Property] = $change.Actions.Set
                        }
                    }
                    if ($patch.Count -gt 0 -and $result.GraphResource.id) {
                        $requestUrl = "$script:graphBaseUrl/users/{0}" -f $result.GraphResource.id
                        $body = $patch | ConvertTo-Json -ErrorAction Stop
                        Write-PSFMessage -Level Verbose -String 'TMF.Invoke.SendingRequestWithBody' -StringValues 'PATCH', $requestUrl, $body
                        Invoke-MgGraphRequest -Method PATCH -Uri $requestUrl -Body $body | Out-Null
                    }
                }
            }
        }
    }
}
