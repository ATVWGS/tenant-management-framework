function Resolve-String
{
	[CmdletBinding()]
	Param (
		[string[]] $Text
	)
	
	begin
	{
		[regex] $mappingRegex = "{{ ([\dA-Za-z]*) }}"
	}
	process
	{
		foreach ($item in $Text) {
			foreach ($match in $mappingRegex.Matches($item)) {
				$replaceValue = $script:desiredConfiguration["stringMappings"] | Where-Object {$_.name -eq $match.Groups[1].Value}
				if ($replaceValue) {
					$item = $item -replace $match.Value, $replaceValue.replace
				}
			}
			$item
		}
	}
}