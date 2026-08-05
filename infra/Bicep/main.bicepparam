// ----------------------------------------------------------------------------------------------------
// Shared Pipeline Parameter File (Azure DevOps + GitHub Actions)
// ----------------------------------------------------------------------------------------------------
using './main.bicep'

param appName = '#{APP_NAME}#'
param environmentCode = '#{ENVCODE}#'
param location = '#{RESOURCE_GROUP_LOCATION}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'
param deploymentType = 'webapp'
param addRoleAssignments = true
param createUserAssignedIdentity = true

param servicePlanName = '#{EXISTING_SERVICEPLAN_NAME}#'
param servicePlanResourceGroupName = '#{EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME}#'
param webAppKind = 'linux' // 'linux' or 'windows'
param existingLogAnalyticsWorkspaceName = '#{EXISTING_LOG_ANALYTICS_WORKSPACE}#'
param existingLogAnalyticsWorkspaceResourceGroupName = '#{EXISTING_LOG_ANALYTICS_WORKSPACE_RESOURCE_GROUP_NAME}#'

// param adminUserId = '#{KEYVAULT_OWNER_USERID}#'

param azureFoundryResourceUrl = '#{FOUNDRY_RESOURCE_URL}#'
param azureModelName = '#{MODEL_NAME}#'
