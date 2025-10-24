function Add-TmfCacheEntries {
    <#
    .SYNOPSIS
    Adds objects to a script-scoped detail cache using multiple key properties.
    .PARAMETER CacheName
    Name (without $script:) of the script-scoped hashtable cache (e.g. 'userDetailCache'). Created if missing.
    .PARAMETER Objects
    Array of PSCustomObjects to add.
    .PARAMETER KeyProperties
    Properties on each object whose values should be used as keys (null / empty ignored).
    #>
    [CmdletBinding()] param(
        [Parameter(Mandatory)][string]$CacheName,
        [Parameter(Mandatory)][object[]]$Objects,
        [Parameter(Mandatory)][string[]]$KeyProperties
    )
    if (-not $Objects -or $Objects.Count -eq 0) {
        return 
    }
    $var = Get-Variable -Name $CacheName -Scope script -ErrorAction SilentlyContinue
    if (-not $var) {
        Set-Variable -Name $CacheName -Scope script -Value @{}; $var = Get-Variable -Name $CacheName -Scope script 
    }
    $cache = $var.Value
    foreach ($obj in $Objects) {
        if (-not $obj) {
            continue 
        }
        foreach ($kp in $KeyProperties) {
            try {
                $key = $obj.$kp 
            } catch {
                $key = $null 
            }
            if ($key -and -not $cache.ContainsKey($key)) {
                $cache[$key] = $obj 
            }
        }
    }
}

function Test-TmfInputsCached {
    <#
    .SYNOPSIS
    Tests whether all provided inputs are already present in a given script cache.
    .PARAMETER CacheName
    Script scope hashtable cache name.
    .PARAMETER Inputs
    String array of input identifiers.
    .PARAMETER SkipValues
    Values that should be ignored (treated as already satisfied / sentinel tokens).
    .OUTPUTS
    [bool]
    #>
    [CmdletBinding()] param(
        [Parameter(Mandatory)][string]$CacheName,
        [Parameter(Mandatory)][string[]]$Inputs,
        [string[]]$SkipValues = @()
    )
    $var = Get-Variable -Name $CacheName -Scope script -ErrorAction SilentlyContinue
    if (-not $var) {
        return $false 
    }
    $cache = $var.Value
    foreach ($i in $Inputs) {
        if ([string]::IsNullOrWhiteSpace($i)) {
            continue 
        }
        if ($SkipValues -and $i -in $SkipValues) {
            continue 
        }
        if (-not $cache.ContainsKey($i)) {
            return $false 
        }
    }
    return $true
}

function Invoke-TmfArrayResolution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Inputs,
        [scriptblock]$Prefetch,
        [Parameter(Mandatory)][scriptblock]$ResolveSingle
    )
    if (-not $Inputs -or $Inputs.Count -eq 0) {
        return @() 
    }
    if ($Prefetch) {
        & $Prefetch $Inputs 
    }
    $results = @()
    foreach ($i in $Inputs) {
        try {
            $results += & $ResolveSingle $i 
        } catch {
            Write-PSFMessage -Level Warning -Message ("Failed to resolve '{0}': {1}" -f $i, $_.Exception.Message) -Tag failed -ErrorRecord $_; $results += $i 
        }
    }
    return , $results
}
