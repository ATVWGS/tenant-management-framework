# Example roleManagementPolicyRuleTemplates.json
# ruleTemplates are used to simplify roleManagementPolicies.json. For each occurance of roleManagementPolicyRules a template has to be created and linked 
# to the specific roleManagementPolicy in roleManagementPolicies.json. Only the approval rule can be managed individually in roleManagementPolicies.json.  

# RoleManagementPolicy ruleset with maximum 9 months eligible assignment possible, permanent active assignment possible and activation duration of 12 hours
```json
{
    "displayName": "AzureAD_Tier0",
    "rules": [
      {
        "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
        "id": "Expiration_Admin_Eligibility",
        "isExpirationRequired": true,
        "maximumDuration": "P270D",
        "target": {
            "caller": "Admin",
            "operations": [
                "All"
            ],
            "level": "Eligibility",
            "inheritableSettings": [],
            "enforcedSettings": []
        }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_Admin_Eligibility",
          "enabledRules": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
          "id": "Expiration_Admin_Assignment",
          "isExpirationRequired": false,
          "maximumDuration": "P270D",
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_Admin_Assignment",
          "enabledRules": [
              "Justification"
          ],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
          "id": "Expiration_EndUser_Assignment",
          "isExpirationRequired": true,
          "maximumDuration": "PT12H",
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_EndUser_Assignment",
          "enabledRules": [
              "Justification"
          ],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyAuthenticationContextRule",
          "id": "AuthenticationContext_EndUser_Assignment",
          "isEnabled": false,
          "claimValue": null,
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      }
    ]
  }
  ```

  # RoleManagementPolicy ruleset for Azure resource role 

  ```json
  [
    {
        "displayname": "Azure resource role template",
        "rules": [
            {
                "isExpirationRequired": false,
                "maximumDuration": "P365D",
                "id": "Expiration_Admin_Eligibility",
                "ruleType": "RoleManagementPolicyExpirationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Eligibility"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Admin",
                "isDefaultRecipientsEnabled": false,
                "notificationLevel": "All",
                "id": "Notification_Admin_Admin_Eligibility",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Eligibility"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Requestor",
                "isDefaultRecipientsEnabled": true,
                "notificationLevel": "All",
                "id": "Notification_Requestor_Admin_Eligibility",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Eligibility"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Approver",
                "isDefaultRecipientsEnabled": true,
                "notificationLevel": "All",
                "id": "Notification_Approver_Admin_Eligibility",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Eligibility"
                }
            },
            {
                "enabledRules": [],
                "id": "Enablement_Admin_Eligibility",
                "ruleType": "RoleManagementPolicyEnablementRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Eligibility"
                }
            },
            {
                "isExpirationRequired": false,
                "maximumDuration": "P180D",
                "id": "Expiration_Admin_Assignment",
                "ruleType": "RoleManagementPolicyExpirationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "enabledRules": [
                "Justification"
                ],
                "id": "Enablement_Admin_Assignment",
                "ruleType": "RoleManagementPolicyEnablementRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Admin",
                "isDefaultRecipientsEnabled": false,
                "notificationLevel": "All",
                "id": "Notification_Admin_Admin_Assignment",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Requestor",
                "isDefaultRecipientsEnabled": true,
                "notificationLevel": "All",
                "id": "Notification_Requestor_Admin_Assignment",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Approver",
                "isDefaultRecipientsEnabled": true,
                "notificationLevel": "All",
                "id": "Notification_Approver_Admin_Assignment",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "Admin",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "isExpirationRequired": false,
                "maximumDuration": "PT10H",
                "id": "Expiration_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyExpirationRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "enabledRules": [
                "Justification"
                ],
                "id": "Enablement_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyEnablementRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "setting": {
                "isApprovalRequired": false,
                "isApprovalRequiredForExtension": false,
                "isRequestorJustificationRequired": true,
                "approvalMode": "SingleStage",
                "approvalStages": [
                    {
                    "approvalStageTimeOutInDays": 1,
                    "isApproverJustificationRequired": true,
                    "escalationTimeInMinutes": 0,
                    "primaryApprovers": [],
                    "isEscalationEnabled": false
                    }
                ]
                },
                "id": "Approval_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyApprovalRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "isEnabled": false,
                "claimValue": "",
                "id": "AuthenticationContext_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyAuthenticationContextRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Admin",
                "isDefaultRecipientsEnabled": false,
                "notificationLevel": "All",
                "id": "Notification_Admin_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Requestor",
                "isDefaultRecipientsEnabled": true,
                "notificationLevel": "All",
                "id": "Notification_Requestor_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            },
            {
                "notificationType": "Email",
                "recipientType": "Approver",
                "isDefaultRecipientsEnabled": true,
                "notificationLevel": "All",
                "id": "Notification_Approver_EndUser_Assignment",
                "ruleType": "RoleManagementPolicyNotificationRule",
                "target": {
                "caller": "EndUser",
                "operations": [
                    "All"
                ],
                "level": "Assignment"
                }
            }
        ]
    }
]
```

# RoleManagementPolicy ruleset with maximum 9 months eligible assignment possible, permanent active assignment possible and activation duration of 12 hours for AADGroups
```json
{
    "displayName": "PrivilegedAccessGroups",
    "rules": [
      {
        "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
        "id": "Expiration_Admin_Eligibility",
        "isExpirationRequired": true,
        "maximumDuration": "P270D",
        "target": {
            "caller": "Admin",
            "operations": [
                "All"
            ],
            "level": "Eligibility",
            "inheritableSettings": [],
            "enforcedSettings": []
        }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_Admin_Eligibility",
          "enabledRules": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_Admin_Eligibility",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Eligibility",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
          "id": "Expiration_Admin_Assignment",
          "isExpirationRequired": false,
          "maximumDuration": "P270D",
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_Admin_Assignment",
          "enabledRules": [
              "Justification"
          ],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_Admin_Assignment",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "Admin",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule",
          "id": "Expiration_EndUser_Assignment",
          "isExpirationRequired": true,
          "maximumDuration": "PT12H",
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule",
          "id": "Enablement_EndUser_Assignment",
          "enabledRules": [
              "Justification"
          ],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyAuthenticationContextRule",
          "id": "AuthenticationContext_EndUser_Assignment",
          "isEnabled": false,
          "claimValue": null,
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Admin_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Admin",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Requestor_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Requestor",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      },
      {
          "@odata.type": "#microsoft.graph.unifiedRoleManagementPolicyNotificationRule",
          "id": "Notification_Approver_EndUser_Assignment",
          "notificationType": "Email",
          "recipientType": "Approver",
          "notificationLevel": "All",
          "isDefaultRecipientsEnabled": true,
          "notificationRecipients": [],
          "target": {
              "caller": "EndUser",
              "operations": [
                  "All"
              ],
              "level": "Assignment",
              "inheritableSettings": [],
              "enforcedSettings": []
          }
      }
    ]
  }
  ```