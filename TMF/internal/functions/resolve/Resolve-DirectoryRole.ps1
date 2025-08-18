function Resolve-DirectoryRole {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true)][string]$InputReference,
		[switch]$DontFailIfNotExisting,
		[switch]$SearchInDesiredConfiguration,
		[switch]$Expand, # Return object { id, displayName, roleTemplateId }
		[switch]$DisplayName,
		[System.Management.Automation.PSCmdlet]$Cmdlet = $PSCmdlet
	)
	begin {
		if (Get-Command Resolve-String -ErrorAction SilentlyContinue) { $InputReference = Resolve-String -Text $InputReference } else { $InputReference = $InputReference.Trim() }
		if (-not $script:directoryRoleDetailCache) { $script:directoryRoleDetailCache = @{} }

		function Get-AllGraphPages {
			param(
				[string]$Uri
			)
			$results = @()
			$next = $Uri
			while ($next) {
				$response = Invoke-MgGraphRequest -Method GET -Uri $next
				if ($response.value) { $results += $response.value }
				$next = $response.'@odata.nextLink'
			}
			return $results
		}

		# Static fallback for built-in directory role templates (subset most frequently encountered)
		if (-not $script:builtInDirectoryRoleTemplates) {
			$script:builtInDirectoryRoleTemplates = @(
				# id (roleTemplateId)                              displayName
				[pscustomobject]@{ id='62e90394-69f5-4237-9190-012177145e10'; displayName='Global Administrator' }
				[pscustomobject]@{ id='fe930be7-5e62-47db-91af-98c3a49a38b1'; displayName='Privileged Role Administrator' }
				[pscustomobject]@{ id='29232cdf-9323-42fd-ade2-1d097af3e4de'; displayName='Security Administrator' }
				[pscustomobject]@{ id='194ae4cb-b126-40b2-bd5b-6091b380977d'; displayName='Conditional Access Administrator' }
				[pscustomobject]@{ id='b0f54661-2d74-4c50-afa3-1ec803f12efe'; displayName='Helpdesk Administrator' }
				[pscustomobject]@{ id='729827e3-9c14-49f7-bb1b-9608f156bbb8'; displayName='User Administrator' }
				[pscustomobject]@{ id='f28a1f50-f6e7-4571-818b-6a12f2af6b6c'; displayName='Authentication Administrator' }
				[pscustomobject]@{ id='e8611ab8-c189-46e8-94e1-60213ab1f814'; displayName='Intune Administrator' }
				[pscustomobject]@{ id='e300d9e7-4a2b-4295-9eff-f1c78b36cc98'; displayName='Cloud Application Administrator' }
				[pscustomobject]@{ id='cf1c38e5-3621-4004-a7cb-879624dced7c'; displayName='Compliance Administrator' }
				[pscustomobject]@{ id='158c047a-c907-4556-b7ef-446551a6b5f7'; displayName='Groups Administrator' }
				[pscustomobject]@{ id='966707d0-3269-4727-9be2-8c3a10f19b9d'; displayName='Password Administrator' }
				[pscustomobject]@{ id='194ae4cb-b126-40b2-bd5b-6091b380977d'; displayName='Conditional Access Administrator' }
				[pscustomobject]@{ id='fdd7a751-b60b-444a-984c-02652fe8fa1c'; displayName='Billing Administrator' }
				[pscustomobject]@{ id='17315797-102d-40b4-93e0-432062caca18'; displayName='Application Administrator' }
				[pscustomobject]@{ id='a9ea8996-122f-4c74-9520-8edcd192826c'; displayName='Azure DevOps Administrator' }
				[pscustomobject]@{ id='f23f5ca3-344d-4017-83bd-1d56baf79882'; displayName='Reports Reader' }
			)
		}
	}
	process {
		try {
			if ($InputReference -in @('All')) { if ($Expand) { return [pscustomobject]@{ id='All'; displayName='All'; roleTemplateId=$null } } return 'All' }
			if ($Expand -and $script:directoryRoleDetailCache.ContainsKey($InputReference)) { return $script:directoryRoleDetailCache[$InputReference] }

			$roleId = $null; $detail = $null; $source = $null

			# 1. Try active directoryRoles (only returns activated roles) - tolerate 404s
			try {
				if ($InputReference -match $script:guidRegex) {
					$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles?`$filter=id eq '{0}'&`$select=id,displayName,roleTemplateId" -f $InputReference)).value | Select-Object -First 1
					if ($detail) { $roleId = $detail.id; $source = 'directoryRoles' }
				} else {
					$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles?`$filter=displayName eq '{0}'&`$select=id,displayName,roleTemplateId" -f $InputReference)).value | Select-Object -First 1
					if ($detail) { $roleId = $detail.id; $source = 'directoryRoles' }
				}
			} catch { Write-PSFMessage -Level Verbose -Message "directoryRoles lookup (id/displayName) failed for ${InputReference}: $($_.Exception.Message)" }

			# 1a. If still not found & looks like GUID, try active roles by roleTemplateId
			if (-not $roleId -and $InputReference -match $script:guidRegex) {
				try {
					$detail = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles?`$filter=roleTemplateId eq '{0}'&`$select=id,displayName,roleTemplateId" -f $InputReference)).value | Select-Object -First 1
					if ($detail) { $roleId = $detail.id; $source = 'directoryRoles' }
				} catch { Write-PSFMessage -Level Verbose -Message "directoryRoles lookup (roleTemplateId) failed for ${InputReference}: $($_.Exception.Message)" }
			}

			# 1b. Targeted roleDefinitions lookup (single GET) - handles when caller passes a roleDefinition id (custom role) directly
			if (-not $roleId -and $InputReference -match $script:guidRegex) {
				try {
					$singleDef = Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/roleManagement/directory/roleDefinitions/$InputReference?`$select=id,displayName,templateId,isBuiltIn") -ErrorAction Stop
					if ($singleDef) { $detail = $singleDef; $roleId = $detail.id; $source = 'roleDefinitions-single' }
				} catch { if ($_.Exception.Message -notmatch '404') { Write-PSFMessage -Level Verbose -Message "Single roleDefinition fetch failed for ${InputReference}: $($_.Exception.Message)" } }
			}

			# 1c. Targeted roleDefinitions lookup by templateId (filter) - used when InputReference is a templateId, not the roleDefinition id
			if (-not $roleId -and $InputReference -match $script:guidRegex) {
				try {
					$filteredDef = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/roleManagement/directory/roleDefinitions?`$filter=templateId eq '{0}'&`$select=id,displayName,templateId,isBuiltIn" -f $InputReference)).value | Select-Object -First 1
					if ($filteredDef) { $detail = $filteredDef; $roleId = $detail.id; $source = 'roleDefinitions-filter' }
				} catch { if ($_.Exception.Message -notmatch '404') { Write-PSFMessage -Level Verbose -Message "Filtered roleDefinition fetch failed for templateId ${InputReference}: $($_.Exception.Message)" } }
			}

			# 2. Fallback to directoryRoleTemplates (built-in) if not active
			if (-not $roleId) {
				if (-not $script:directoryRoleTemplatesCache) {
					$script:directoryRoleTemplatesCache = @()
					$endpoints = @("$script:graphBaseUrl/directoryRoleTemplates?`$select=id,displayName")
					# Try version fallback if we are on beta
					if ($script:graphBaseUrl -match '/beta$') { $endpoints += ($script:graphBaseUrl -replace '/beta$','/v1.0') + '/directoryRoleTemplates?`$select=id,displayName' }
					foreach ($ep in $endpoints) {
						try {
							$script:directoryRoleTemplatesCache = Get-AllGraphPages -Uri $ep
							if ($script:directoryRoleTemplatesCache.Count -gt 0) { break }
						} catch {
							Write-PSFMessage -Level Verbose -Message "DirectoryRoleTemplates fetch failed for $($ep): $($_.Exception.Message)"
						}
					}
					if (-not $script:directoryRoleTemplatesCache -or $script:directoryRoleTemplatesCache.Count -eq 0) {
						# Use static fallback mapping
						$script:directoryRoleTemplatesCache = $script:builtInDirectoryRoleTemplates
					}
					else {
						# Ensure objects have uniform shape (id, displayName)
						$script:directoryRoleTemplatesCache = $script:directoryRoleTemplatesCache | Select-Object @{n='id';e={$_['id']}}, @{n='displayName';e={$_['displayName']}}
					}
				}
				if ($InputReference -match $script:guidRegex) {
					$detail = $script:directoryRoleTemplatesCache | Where-Object { $_.id -eq $InputReference } | Select-Object -First 1
				} else {
					$detail = $script:directoryRoleTemplatesCache | Where-Object { $_.displayName -eq $InputReference } | Select-Object -First 1
				}
				if ($detail) { $roleId = $detail.id; $source = 'directoryRoleTemplates' }
			}

			# 3. Fallback to roleDefinitions (custom roles or built-in definitions) with paging & version fallback
			if (-not $roleId) {
				if (-not $script:directoryRoleDefinitionsCache) {
					$script:directoryRoleDefinitionsCache = @()
					$endpoints = @("$script:graphBaseUrl/roleManagement/directory/roleDefinitions?`$select=id,displayName,templateId,isBuiltIn")
					if ($script:graphBaseUrl -match '/beta$') { $endpoints += ($script:graphBaseUrl -replace '/beta$','/v1.0') + '/roleManagement/directory/roleDefinitions?`$select=id,displayName,templateId,isBuiltIn' }
					foreach ($ep in $endpoints) {
						try {
							$script:directoryRoleDefinitionsCache = Get-AllGraphPages -Uri $ep
							if ($script:directoryRoleDefinitionsCache.Count -gt 0) { break }
						} catch {
							Write-PSFMessage -Level Verbose -Message "DirectoryRoleDefinitions fetch failed for $($ep): $($_.Exception.Message)"
						}
					}
				}
				if ($InputReference -match $script:guidRegex) {
					$detail = $script:directoryRoleDefinitionsCache | Where-Object { $_.id -eq $InputReference -or $_.templateId -eq $InputReference } | Select-Object -First 1
				} else {
					$detail = $script:directoryRoleDefinitionsCache | Where-Object { $_.displayName -eq $InputReference } | Select-Object -First 1
				}
				if ($detail) { $roleId = $detail.id; $source = 'roleDefinitions' }
			}

			if (-not $roleId -and $SearchInDesiredConfiguration) { if ($InputReference -in $script:desiredConfiguration['directoryRoles'].displayName) { $roleId = $InputReference; $detail = [pscustomobject]@{ id=$roleId; displayName=$InputReference; roleTemplateId=$null }; $source='desiredConfig' } }

			if (-not $roleId) {
				if ($DontFailIfNotExisting) { return $InputReference }
				else { throw "Cannot find directoryRole $InputReference across active roles, templates, or role definitions." }
			}

			if (-not $Expand) {
				if ($DisplayName) {
					if (-not $detail) { return (Resolve-DirectoryRole -InputReference $roleId -Expand -DontFailIfNotExisting:$DontFailIfNotExisting -SearchInDesiredConfiguration:$SearchInDesiredConfiguration -Cmdlet $Cmdlet).displayName }
					return ($detail.displayName ?? $InputReference)
				}
				return $roleId
			}

			# Normalize detail object fields (roleTemplateId preference)
			$roleTemplateId = $null
			if ($source -eq 'directoryRoles') { $roleTemplateId = $detail.roleTemplateId }
			elseif ($source -eq 'directoryRoleTemplates') { $roleTemplateId = $detail.id }
			elseif ($source -eq 'roleDefinitions') { $roleTemplateId = $detail.templateId }
			if (-not $detail.displayName) { $displayName = $InputReference } else { $displayName = $detail.displayName }
			$obj = [pscustomobject]@{ id=$roleId; displayName=$displayName; roleTemplateId=$roleTemplateId }
			foreach ($key in @($obj.id,$obj.displayName,$obj.roleTemplateId)) { if ($key -and -not $script:directoryRoleDetailCache.ContainsKey($key)) { $script:directoryRoleDetailCache[$key] = $obj } }
			return $obj
		}
		catch {
			if ($DontFailIfNotExisting) { Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRole resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; return $InputReference } else { Write-PSFMessage -Level Warning -Message ("Cannot resolve DirectoryRole resource for input '{0}'. Searched tenant & desired configuration. Error: {1}" -f $InputReference,$_.Exception.Message) -Tag failed -ErrorRecord $_; $Cmdlet.ThrowTerminatingError($_) }
		}
	}
}