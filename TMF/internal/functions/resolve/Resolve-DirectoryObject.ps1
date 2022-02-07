function Resolve-DirectoryObject
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
				$directoryObject = (Get-MgDirectoryObject -DirectoryObjectId $InputReference).Id
			}

			if (-Not $directoryObject -and -Not $DontFailIfNotExisting) { throw "Cannot find directoryObject $InputReference" } 
			elseif (-Not $directoryObject -and $DontFailIfNotExisting) { return }

			if ($directoryObject.count -gt 1) { throw "Got multiple directoryObject for $InputReference" }
			return $directoryObject
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "DirectoryObject" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}
