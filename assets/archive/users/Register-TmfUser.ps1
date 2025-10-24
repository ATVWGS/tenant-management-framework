function Register-TmfUser {
    [CmdletBinding()] param(
        [Parameter(Mandatory = $true)] [string] $userPrincipalName,
        [Parameter(Mandatory = $true)] [string] $displayName,
        [bool] $accountEnabled = $true,
        [string] $mailNickname = ($userPrincipalName.Split('@')[0]),
        [string] $givenName,
        [string] $surname,
        [string] $userType,
        [bool] $present = $true,
        [string] $sourceConfig = '<Custom>',
        [string] $sourceFile = '<Custom>',
        [System.Management.Automation.PSCmdlet] $Cmdlet = $PSCmdlet
    )
    begin {
        $resourceName = 'users'
        if (-not $script:desiredConfiguration[$resourceName]) {
            $script:desiredConfiguration[$resourceName] = @() 
        }
        if ($script:desiredConfiguration[$resourceName].userPrincipalName -contains $userPrincipalName) {
            $alreadyLoaded = $script:desiredConfiguration[$resourceName] | Where-Object { $_.userPrincipalName -eq $userPrincipalName }
        }
    }
    process {
        if (Test-PSFFunctionInterrupt) {
            return 
        }
        $object = [PSCustomObject] @{
            userPrincipalName = Resolve-String -Text $userPrincipalName
            displayName       = Resolve-String -Text $displayName
            accountEnabled    = $accountEnabled
            mailNickname      = $mailNickname
            givenName         = $givenName
            surname           = $surname
            userType          = $userType
            present           = $present
            sourceConfig      = $sourceConfig
            sourceFile        = $sourceFile
        }
        Add-Member -InputObject $object -MemberType ScriptMethod -Name Properties -Value { ($this | Get-Member -MemberType NoteProperty).Name }
        if ($alreadyLoaded) {
            $script:desiredConfiguration[$resourceName][$script:desiredConfiguration[$resourceName].IndexOf($alreadyLoaded)] = $object 
        } else {
            $script:desiredConfiguration[$resourceName] += $object 
        }
    }
}
