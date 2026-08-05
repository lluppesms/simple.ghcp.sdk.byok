// ----------------------------------------------------------------------------------------------------
// Shared Pipeline Parameter File (Azure DevOps + GitHub Actions)
// ----------------------------------------------------------------------------------------------------
using './main.bicep'

param appName = '#{APP_NAME}#'
param environmentCode = '#{ENVCODE}#'
param location = '#{RESOURCE_GROUP_LOCATION}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'

param azureFoundryResourceUrl = '#{FOUNDRY_RESOURCE_URL}#'
param azureModelName = '#{MODEL_NAME}#'
param azureEntraTenantId = '#{ENTRA_TENANT_ID}#'

param servicePlanName = '#{EXISTING_SERVICEPLAN_NAME}#'
param servicePlanResourceGroupName = '#{EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME}#'
