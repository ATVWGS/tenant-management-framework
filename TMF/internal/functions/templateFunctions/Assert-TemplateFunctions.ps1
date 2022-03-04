function Assert-TemplateFunctions
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputTemplate
	)

	begin
	{
		function Check-StringMappingsExists {
			Param (
				[Parameter(Mandatory = $true)]
				[string] $StringMappingName
			)

			if ($StringMappingName -in $script:desiredConfiguration["stringMappings"].name)
			{
				return $true
			}
			return $false
		}

		function Get-ValueFromStringMappings {
			Param (
				[Parameter(Mandatory = $true)]
				[string] $StringMappingName
			)
			
			if (Check-StringMappingsExists -StringMappingName $StringMappingName) {				
				return ($script:desiredConfiguration["stringMappings"] | Where-Object {$_.name -eq $StringMappingName}).replace
			}
			return $StringMappingName
		}

		[regex] $functionRegex = "(?<pre_comma>,?)\n?\s*`"?(?<to_replace>{% (?<function>for|if) (?<statement>[\w\s\'\-_]*) %}\s?(?<output>[\w\s\-_!§`$&\/\(\)=\?\\`"\[\]:,{}]*)\s?{% (endfor|endif) %})`"?"
		[regex] $ifStatementRegex = "\'?(?<left>[\w\-_]+)\'? (?<operator>eq|ne) \'?(?<right>[\w\-_]+)\'?"
	}
	process
	{	
		$functionMatches = $functionRegex.Matches($InputTemplate)			
		if ($functionMatches.count -eq 0) {
			Write-Debug "Found $($functionMatches.count) matches"
			$InputTemplate
			return
		}

		foreach ($functionMatch in ($functionMatches | Sort-Object -Unique Value )) { 
			# If the same function is used multiple times, we only evaluate it once. We replace all recurrences.
			Write-Debug "Found function $functionMatch"			
			switch ($functionMatch.Groups["function"].Value) {				
				"if" {					
					Write-Debug "Is an if-function"
					$statementMatch = $ifStatementRegex.Match($functionMatch.Groups["statement"].Value)					
					$left = if ($statementMatch.Groups["left"].value -notlike "'*'") { Get-ValueFromStringMappings -StringMappingName $statementMatch.Groups["left"].Value } else { $statementMatch.Groups["left"].value }
					$right = if ($statementMatch.Groups["right"].value -notlike "'*'") { Get-ValueFromStringMappings -StringMappingName $statementMatch.Groups["right"].Value } else { $statementMatch.Groups["right"].value }											

					switch ($statementMatch.Groups["operator"].Value) {
						"eq" {
							Write-Debug "Operator is eq"
							if ($left -eq $right) {
								Write-Debug "Statement is '$statementMatch' returns true. Replacing with output value"
								Write-Debug "Replacing $($functionMatch.Groups["to_replace"].Value) with $($functionMatch.Groups["output"].Value)"
								$InputTemplate = $InputTemplate.replace($functionMatch.Groups["to_replace"].Value, $functionMatch.Groups["output"].Value)
							}
							else {
								Write-Debug "Statement is '$statementMatch' returns false. Replacing with empty"
								$InputTemplate = $InputTemplate.replace($functionMatch.Value, "")
							}
						}
						"ne" {
							Write-Debug "Operator is ne"
							if ($left -ne $right) {
								Write-Debug "Output value: $($functionMatch.Groups["output"].Value)"
								Write-Debug "Replacing $($functionMatch.Groups["to_replace"].Value) with $($functionMatch.Groups["output"].Value)"
								$InputTemplate = $InputTemplate.replace($functionMatch.Groups["to_replace"].Value, $functionMatch.Groups["output"].Value)
							}
							else {
								Write-Debug "Statement is '$statementMatch' returns false. Replacing with empty"
								$InputTemplate = $InputTemplate.replace($functionMatch.Value, "")
							}
						}
					}
				}					
			}				
		}
		$InputTemplate
	}
}
