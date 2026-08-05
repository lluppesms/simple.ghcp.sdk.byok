// --------------------------------------------------------------------------------
// Main Bicep file that creates all of the Azure Resources for one environment
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n "manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')" --resource-group rg_test --template-file 'main.bicep' --parameters appName=xxx-test environmentCode=test keyVaultOwnerUserId=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'azd'
param location string = resourceGroup().location
param instanceNumber string = '1'

param deploymentType string = 'webapp'

param servicePlanName string = ''
param servicePlanResourceGroupName string = '' // if using an existing service plan in a different resource group

param webAppKind string = 'linux' // 'linux' or 'windows'
param webSiteSku string = 'B1'

param azureFoundryResourceUrl string = ''
param azureFoundryName string = ''
param azureFoundryResourceGroup string = ''
param azureEntraTenantId string = ''
param azureModelName string = ''

@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true

@description('Create a separate user-assigned managed identity. When false, each resource uses its own system-assigned identity.')
param createUserAssignedIdentity bool = true

// calculated variables disguised as parameters
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var existingServicePlanNameEffective = empty(trim(servicePlanName)) || contains(servicePlanName, '#{') ? '' : trim(servicePlanName)
var existingServicePlanRgNameEffective = empty(trim(servicePlanResourceGroupName)) || contains(servicePlanResourceGroupName, '#{') ? '' : trim(servicePlanResourceGroupName)
var effectiveManagedIdentityId = createUserAssignedIdentity ? identity!.outputs.managedIdentityId : ''
var effectiveManagedIdentityPrincipalId = createUserAssignedIdentity ? identity!.outputs.managedIdentityPrincipalId : ''
var effectiveManagedIdentityClientId = createUserAssignedIdentity ? identity!.outputs.managedIdentityClientId : ''
var commonTags = {
  LastDeployed: runDateTime
  Application: appName
  Environment: environmentCode
}
var resourceGroupName = resourceGroup().name
var deploymentTypeNormalized = toLower(deploymentType)
var deployWebAppEffective = contains(['webapp', 'all'], deploymentTypeNormalized)

// --------------------------------------------------------------------------------
module resourceNames 'resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    appName: appName
    environmentCode: environmentCode
    instanceNumber: instanceNumber
  }
}

// --------------------------------------------------------------------------------
// Find existing Azure Foundry  instance
// --------------------------------------------------------------------------------
resource existingFoundry 'Microsoft.CognitiveServices/accounts@2026-05-15-preview' existing = {
  scope: resourceGroup(azureFoundryResourceGroup)
  name: azureFoundryName
}

// --------------------------------------------------------------------------------
// Identity and Role Assignments
// --------------------------------------------------------------------------------
module identity './modules/iam/identity.bicep' = if (createUserAssignedIdentity) {
  name: 'appIdentity${deploymentSuffix}'
  params: {
    identityName: resourceNames.outputs.userAssignedIdentityName
    location: location
  }
}

// Add AI User Role to the managed identity
module appRoleAssignments './modules/iam/aiuserroleassignment.bicep' = if (addRoleAssignments && createUserAssignedIdentity) {
  name: 'appRoleAssignments${deploymentSuffix}'
  params: {
    identityPrincipalId: identity!.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    aiServicesName: existingFoundry.name
    aiServicesResourceGroup: azureFoundryResourceGroup
  }
}

// // also add rights to the web app storage account (App Service only)
// module appRoleAssignments2 './modules/iam/aiuserroleassignment.bicep' = if (addRoleAssignments && deployWebAppEffective) {
//   name: 'appRoleAssignments-webapp-storage${deploymentSuffix}'
//   params: {
//     identityPrincipalId: webSiteModule!.outputs.systemPrincipalId
//     principalType: 'ServicePrincipal'
//     aiServicesName: existingFoundry.name
//   }
// }

// --------------------------------------------------------------------------------
// App Service Infrastructure (deployed when deploymentType is webapp/appservice alias or all)
// --------------------------------------------------------------------------------
module appServicePlanModule './modules/webapp/websiteserviceplan.bicep' = if (deployWebAppEffective) {
  name: 'appService${deploymentSuffix}'
  params: {
    location: location
    commonTags: commonTags
    sku: webSiteSku
    appServicePlanName: empty(existingServicePlanNameEffective) ? resourceNames.outputs.webSiteAppServicePlanName : existingServicePlanNameEffective
    existingServicePlanName: existingServicePlanNameEffective
    existingServicePlanResourceGroupName: existingServicePlanRgNameEffective
    webAppKind: webAppKind
  }
}

module webSiteModule './modules/webapp/website.bicep' = if (deployWebAppEffective) {
  name: 'webSite${deploymentSuffix}'
  params: {
    webSiteName: resourceNames.outputs.webSiteName
    location: location
    commonTags: commonTags
    environmentCode: environmentCode
    webAppKind: webAppKind
    managedIdentityId: effectiveManagedIdentityId
    managedIdentityPrincipalId: effectiveManagedIdentityPrincipalId
    appServicePlanName: appServicePlanModule!.outputs.name
    appServicePlanResourceGroupName: appServicePlanModule!.outputs.resourceGroupName
    // In a Linux app service, any nested JSON app key like AppSettings:MyKey needs to be 
    // configured in App Service as AppSettings__MyKey for the key name. 
    // In other words, any : should be replaced by __ (double underscore).
    // NOTE: See https://learn.microsoft.com/en-us/azure/app-service/configure-common?tabs=portal
    customAppSettings: {
      AZURE_CLIENT_ID: effectiveManagedIdentityClientId
      AZURE_TOKEN_CREDENTIALS: 'ManagedIdentityCredential'
      LANG: 'en_US.UTF-8'
      LC_ALL: 'en_US.UTF-8'
      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT: 'false'
      Azure__EntraTenantId: azureEntraTenantId
      Azure__FoundryResourceUrl: azureFoundryResourceUrl
      Azure__ModelName: azureModelName
      Azure__TokenScope: 'https://cognitiveservices.azure.com/.default'
    }
  }
}

// --------------------------------------------------------------------------------
// Outputs
// --------------------------------------------------------------------------------
output SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_NAME string = resourceGroupName
output DEPLOYMENT_TYPE string = deploymentTypeNormalized
output WEB_HOST_NAME string = deployWebAppEffective ? webSiteModule!.outputs.hostName : ''
output WEB_URL string = deployWebAppEffective ? 'https://${webSiteModule!.outputs.hostName}' : ''
output USER_ASSIGNED_IDENTITY_CLIENT_ID string = effectiveManagedIdentityClientId
