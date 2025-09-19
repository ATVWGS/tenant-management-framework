<#
DEPRECATED: This helper has been superseded by Resolve-DirectoryObject which now implements
batch /directoryObjects/getByIds logic internally (see modernization guideline §9a).
File retained temporarily because deletion attempts via automated patch tooling did not persist.
It is intentionally inert and will be removed in a future cleanup commit.
#>
function Invoke-TmfDirectoryObjectsGetByIds {
    [CmdletBinding()] param()
    Write-PSFMessage -Level Warning -Message 'Invoke-TmfDirectoryObjectsGetByIds is deprecated. Use Resolve-DirectoryObject instead.' -Tag 'deprecated'
    return @()
}
