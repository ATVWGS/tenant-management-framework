function Resolve-DirectoryRole
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[string] $InputReference,
		[switch] $DontFailIfNotExisting,
		[switch] $DisplayName,
		[switch] $Expand, # Return object { id, displayName, roleTemplateId }
		[switch] $SearchInDesiredConfiguration,
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
				$response = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles?`$filter=id eq '{0}'" -f $InputReference)).Value
				if ($DisplayName) {
					$role = $reponse.displayName	
				}
				elseif ($Expand) {
					$role = [pscustomObject]@{id = $response.id; displayName = $response.displayName; roleTemplateId = $response.roleTemplateId}
				}
				else {
					$role = $response.Id
				}
			}
			elseif ($InputReference -in @("All")) {
				return $InputReference
			}
			else {
				$response = (Invoke-MgGraphRequest -Method GET -Uri ("$script:graphBaseUrl/directoryRoles/?`$filter=displayName eq '{0}'" -f $InputReference)).Value
				if ($DisplayName) {
					$role = $reponse.displayName	
				}
				elseif ($Expand) {
					if ($response) {
						$role = [pscustomObject]@{id = $response.id; displayName = $response.displayName; roleTemplateId = $response.roleTemplateId}
					}
					else {
						$role = $null
					}
				}
				else {
					$role = $response.Id
				}
			}

			if (-Not $role -and $SearchInDesiredConfiguration) {
				if ($InputReference -in $script:desiredConfiguration["directoryRoles"].displayName) {
					$role = $InputReference
				}
			}

			if (-Not $role -and -Not $DontFailIfNotExisting) { throw "Cannot find directoryRole $InputReference. Directory roles must be activated (assigned) once, before the /directoryRoles endpoint returns them." } 
			elseif (-Not $role -and $DontFailIfNotExisting) { return }

			if ($role.count -gt 1) { throw "Got multiple directoryRoles for $InputReference" }
			return $role
		}
		catch {
			Write-PSFMessage -Level Warning -String 'TMF.CannotResolveResource' -StringValues "DirectoryRole" -Tag 'failed' -ErrorRecord $_
			$Cmdlet.ThrowTerminatingError($_)				
		}			
	}
}


<#function Resolve-DirectoryRole {
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

		# Static fallback for built-in directory role ids (subset most frequently encountered)
		if (-not $script:builtInDirectoryRoleIDs) {
			$script:builtInDirectoryRoleIDs = @(
				# id (id)						                              displayName
				[pscustomobject]@{ id='02fd10fb-8093-42f9-9d4c-8e15b28a31a4'; displayName='Privileged Authentication Administrator' }
				[pscustomobject]@{ id='031b8987-acce-4c1c-84cf-14049decb50c'; displayName='Virtual Visits Administrator' }
				[pscustomobject]@{ id='03f6e934-fbd3-44c8-9d2e-071e6c0e7842'; displayName='Billing Administrator' }
				[pscustomobject]@{ id='07727ddc-a39f-4040-8852-f2498e5714b2'; displayName='B2C IEF Keyset Administrator' }
				[pscustomobject]@{ id='08bc21aa-d584-47d3-af4e-ccf1c57b8942'; displayName='Organizational Messages Writer' }
				[pscustomobject]@{ id='0bc31051-ee53-4444-8383-11647420a9d5'; displayName='Printer Administrator' }
				[pscustomobject]@{ id='0d4cd742-e19a-4516-8b57-a9791aa6a513'; displayName='Teams Telephony Administrator' }
				[pscustomobject]@{ id='0e177a75-70c9-4412-aeb0-bceff2fed254'; displayName='External Identity Provider Administrator' }
				[pscustomobject]@{ id='0f936e51-54dd-426f-839e-19ebb36e752c'; displayName='Cloud App Security Administrator' }
				[pscustomobject]@{ id='112a75ec-1756-4bc1-aebc-76ee06b4d08f'; displayName='Permissions Management Administrator' }
				[pscustomobject]@{ id='115fb7d2-e181-42db-8c1d-47eb0af0262f'; displayName='Message Center Privacy Reader' }
				[pscustomobject]@{ id='17120e1a-7bba-43dc-98ed-25141b59a253'; displayName='Viva Goals Administrator' }
				[pscustomobject]@{ id='172393cf-fd94-4b2c-a807-35bbab390696'; displayName='Teams Reader' }
				[pscustomobject]@{ id='17b317ec-0a74-4895-a614-e995ca8855ed'; displayName='Directory Synchronization Accounts' }
				[pscustomobject]@{ id='1a40cba6-3c8b-4a4d-99e4-8434d0eaa2e4'; displayName='Security Reader' }
				[pscustomobject]@{ id='1c36bb35-580e-4d76-866a-d1311fbd3f16'; displayName='Reports Reader' }
				[pscustomobject]@{ id='1deec988-3c66-42f3-b7f6-e06a3b193ab4'; displayName='Hybrid Identity Administrator' }
				[pscustomobject]@{ id='28fb7145-7940-450d-82e4-1777d39865e3'; displayName='Printer Technician' }
				[pscustomobject]@{ id='291d4fd4-b6cb-4a12-90b4-ba637edeeafd'; displayName='Yammer Administrator' }
				[pscustomobject]@{ id='2d61f11a-0b51-48bd-8f0a-0910d0f7187d'; displayName='Teams Communications Support Specialist' }
				[pscustomobject]@{ id='2e48f57b-a81c-4c8c-abde-28dcdbae8300'; displayName='Password Administrator' }
				[pscustomobject]@{ id='2eabbefb-d50a-48bf-96d7-f6b5de118081'; displayName='Insights Analyst' }
				[pscustomobject]@{ id='2fbe58fb-876d-4390-8710-bdbeb9685f47'; displayName='Helpdesk Administrator' }
				[pscustomobject]@{ id='314ed485-41e3-451b-ba81-062441eacf4d'; displayName='Azure Information Protection Administrator' }
				[pscustomobject]@{ id='35fa4371-8253-463d-8caf-cbf39b46d1a5'; displayName='Exchange Administrator' }
				[pscustomobject]@{ id='3aac6d90-d578-4fc7-980f-0d0dadeacd54'; displayName='Dynamics 365 Administrator' }
				[pscustomobject]@{ id='3cc275b0-6378-4d2d-ba86-16db4e5533df'; displayName='Kaizala Administrator' }
				[pscustomobject]@{ id='404ff205-8d5c-45fc-a85f-a8f2a641ee0a'; displayName='Attribute Assignment Reader' }
				[pscustomobject]@{ id='43169aa1-28cd-4190-bf67-180681af4552'; displayName='Windows Update Deployment Administrator' }
				[pscustomobject]@{ id='4a27f2f0-8e01-442a-96f8-98fe9521a10e'; displayName='Customer LockBox Access Approver' }
				[pscustomobject]@{ id='4a99b72a-029f-4275-83e6-892e920e37cb'; displayName='Attack Simulation Administrator' }
				[pscustomobject]@{ id='4f468c58-6b1e-4529-81a2-d2f7dd28de24'; displayName='Skype for Business Administrator' }
				[pscustomobject]@{ id='501a84c0-3f9b-4040-bf2c-1c744fcd8b0c'; displayName='Insights Administrator' }
				[pscustomobject]@{ id='52a36ffe-eaf0-4314-8135-6d640185bcd3'; displayName='Security Operator' }
				[pscustomobject]@{ id='530d4069-309d-4b4b-adf8-3791f05f75a6'; displayName='Cloud Device Administrator' }
				[pscustomobject]@{ id='530f895b-1383-4cb6-8e8c-17d8f8f83585'; displayName='Directory Readers' }
				[pscustomobject]@{ id='5c07e033-37bb-408d-aa35-ec1b31ac9b2e'; displayName='Search Editor' }
				[pscustomobject]@{ id='5c8daac7-480e-4606-b303-74fb7ba0e6ee'; displayName='Exchange Recipient Administrator' }
				[pscustomobject]@{ id='5dc9d0bc-6254-42f8-8481-957266d65442'; displayName='License Administrator' }
				[pscustomobject]@{ id='5e7d490f-ef5f-43ee-b925-f2874eb1acba'; displayName='Application Administrator' }
				[pscustomobject]@{ id='5ebec292-94ca-4a79-ae21-a49aa91284c0'; displayName='Attribute Assignment Administrator' }
				[pscustomobject]@{ id='61d4bf08-6664-4014-a574-6076f59c132e'; displayName='Office Apps Administrator' }
				[pscustomobject]@{ id='648ca3af-7f37-4b62-8131-03a005670fba'; displayName='Compliance Administrator' }
				[pscustomobject]@{ id='6d7570f7-c82f-44e2-9dcf-aff30fe235a1'; displayName='Message Center Reader' }
				[pscustomobject]@{ id='6faf8ecd-20a1-4489-affb-60813ed92857'; displayName='Organizational Messages Approver' }
				[pscustomobject]@{ id='70b55bd2-689c-4829-a44c-1e1838a2568f'; displayName='Network Administrator' }
				[pscustomobject]@{ id='75840d2d-49db-4b55-bfcc-16917489a94b'; displayName='Teams Devices Administrator' }
				[pscustomobject]@{ id='7594881a-f601-4651-8df4-953c2b999afe'; displayName='External ID User Flow Attribute Administrator' }
				[pscustomobject]@{ id='7620c6dc-6d52-47f5-9959-36deae90250c'; displayName='Azure AD Joined Device Local Administrator' }
				[pscustomobject]@{ id='7862a452-c9b0-442e-9fab-9a56ae8959ce'; displayName='External ID User Flow Administrator' }
				[pscustomobject]@{ id='792ff5be-5d46-4176-aad9-b19f02cab143'; displayName='SharePoint Administrator' }
				[pscustomobject]@{ id='7a5d4ccd-b6e0-4401-990b-76fb7d9f563f'; displayName='Intune Administrator' }
				[pscustomobject]@{ id='7eaee1d5-bd66-40fb-8952-805592252125'; displayName='People Administrator' }
				[pscustomobject]@{ id='7fea9e41-5790-421f-aadc-e2e48bbeec98'; displayName='Search Administrator' }
				[pscustomobject]@{ id='800e0d0a-3547-4479-8d37-70743c63a991'; displayName='Fabric Administrator' }
				[pscustomobject]@{ id='831a2500-a033-4651-9059-8e39a8e0c075'; displayName='Compliance Data Administrator' }
				[pscustomobject]@{ id='83bcd906-2efc-430e-9947-d938b79f9ea6'; displayName='Privileged Role Administrator' }
				[pscustomobject]@{ id='84fed989-27a9-418b-b774-a56e174faf3e'; displayName='Directory Writers' }
				[pscustomobject]@{ id='87debf58-effd-404e-b928-b14ceb87cd6f'; displayName='Authentication Administrator' }
				[pscustomobject]@{ id='8a8ae828-7bdc-4b72-8843-f8360a5ddfbf'; displayName='Teams Administrator' }
				[pscustomobject]@{ id='8ffc422f-425f-40e8-a671-8ffbb9aa79d0'; displayName='User Administrator' }
				[pscustomobject]@{ id='9129f8a5-b1cf-4fd3-ab0c-75beb6ae17b8'; displayName='AI Administrator' }
				[pscustomobject]@{ id='9146a2d1-53da-43bb-bd6d-a121ab3ef5dd'; displayName='Attribute Definition Reader' }
				[pscustomobject]@{ id='965b5e6f-3090-470f-aeee-af2218c9b008'; displayName='Security Administrator' }
				[pscustomobject]@{ id='974024f7-17e7-41b0-af57-88b7150a06e0'; displayName='SharePoint Embedded Administrator' }
				[pscustomobject]@{ id='97b09240-7107-491b-8e7b-972e0f417d38'; displayName='Knowledge Manager' }
				[pscustomobject]@{ id='9a517ff5-6a7e-4cc4-a80c-7beaa55d1f56'; displayName='Global Administrator' }
				[pscustomobject]@{ id='9c729803-098a-4b01-abd4-7bfa285f02ca'; displayName='Tenant Creator' }
				[pscustomobject]@{ id='9cad6895-19af-46ea-806b-b982074abbc2'; displayName='Domain Name Administrator' }
				[pscustomobject]@{ id='9cbce3e6-4053-4229-a0fa-6dbc677b280c'; displayName='Azure DevOps Administrator' }
				[pscustomobject]@{ id='9cbf9ee3-80c4-4cda-a38f-586ce2621978'; displayName='Teams Communications Administrator' }
				[pscustomobject]@{ id='a419b32e-c849-4f24-bb97-503cd6cb21f6'; displayName='Partner Tier1 Support' }
				[pscustomobject]@{ id='a7a932e0-2238-426e-b852-0b01472e3973'; displayName='Partner Tier2 Support' }
				[pscustomobject]@{ id='a9bd1fac-f8b9-4011-aae0-3f70c9a12420'; displayName='Conditional Access Administrator' }
				[pscustomobject]@{ id='b64fb8ac-5fc8-40db-87ba-f92b1bed9652'; displayName='Power Platform Administrator' }
				[pscustomobject]@{ id='b8df4aa7-61d2-4e54-be7c-9d396ff3148b'; displayName='Guest Inviter' }
				[pscustomobject]@{ id='c262f7e2-3e51-40e4-82aa-ebc1e6c5c011'; displayName='Windows 365 Administrator' }
				[pscustomobject]@{ id='cb51289d-3f42-4e7a-a7fe-17b38f7baddc'; displayName='Authentication Policy Administrator' }
				[pscustomobject]@{ id='d25aec8f-f44d-457f-8bd3-36a0058bc46c'; displayName='Attack Payload Author' }
				[pscustomobject]@{ id='d2bb678a-abb4-462d-85dc-a0bc94b811ed'; displayName='Attribute Definition Administrator' }
				[pscustomobject]@{ id='d48713e9-4fe4-4d94-8eef-92732159d187'; displayName='Insights Business Leader' }
				[pscustomobject]@{ id='e024a6d2-7637-4d88-bd8d-a7444c1c6c0e'; displayName='Cloud Application Administrator' }
				[pscustomobject]@{ id='e0a5262f-73a7-46cb-b19e-48baaab54d64'; displayName='Desktop Analytics Administrator' }
				[pscustomobject]@{ id='e14de658-36a1-4f21-a227-3d38b92c0ad9'; displayName='Organizational Data Source Administrator' }
				[pscustomobject]@{ id='e272e12c-1fef-413c-b710-b088ed1b6ca3'; displayName='Global Reader' }
				[pscustomobject]@{ id='e37cb3dd-4566-4c2c-b19b-8fe694154722'; displayName='B2C IEF Policy Administrator' }
				[pscustomobject]@{ id='e56e308d-67af-4bdb-8de6-3790489005ed'; displayName='Service Support Administrator' }
				[pscustomobject]@{ id='eaad0e41-931b-4c18-9c3a-27ac2859eb2c'; displayName='Knowledge Administrator' }
				[pscustomobject]@{ id='ed42e513-46f7-45d3-9867-2abb7e8f8de9'; displayName='Edge Administrator' }
				[pscustomobject]@{ id='ed5f66bf-c4ef-4ea2-a089-a74ce87b456c'; displayName='Identity Governance Administrator' }
				[pscustomobject]@{ id='f1e9b260-3063-4d42-b8cd-803f3c5cf4eb'; displayName='Application Developer' }
				[pscustomobject]@{ id='f6da7101-19e9-4285-b3e7-aba2a544827f'; displayName='Teams Communications Support Engineer' }
				[pscustomobject]@{ id='fc2269d1-e645-428f-8ed4-55a7ba776bb0'; displayName='Usage Summary Reports Reader' }
				[pscustomobject]@{ id='fdc1981c-243a-4dd7-972a-98cfac97f1ff'; displayName='Groups Administrator' }
			)
		}
	}
	process {
		try {
			if ($InputReference -in @('All')) { if ($Expand) { return [pscustomobject]@{ id='All'; displayName='All'; roleTemplateId=$null } } return 'All' }
			if ($Expand -and $script:directoryRoleDetailCache.ContainsKey($InputReference)) { return $script:directoryRoleDetailCache[$InputReference] }

			$roleId = $null; $detail = $null; $source = $null

			# 0. If displayname or -not Expand and role in builtInDirectoryRoleIDs, return directly
			if ($DisplayName -or (-not $Expand)) {
				if ($InputReference -match $script:guidRegex) {
					if ($script:builtInDirectoryRoleTemplates.id -contains $InputReference) {
						return ($script:builtInDirectoryRoleIDs | Where-Object {$_.id -eq $InputReference}).displayName
					}
				}
				else {
					if ($script:builtInDirectoryRoleTemplates.displayName -contains $InputReference) {
						return ($script:builtInDirectoryRoleIDs | Where-Object {$_.displayName -eq $InputReference}).id
					}
				}
			}
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
}#>