// --------------------------------------------------------------------------------
// Main Bicep file that creates all of the Azure Resources for one environment
// --------------------------------------------------------------------------------
// To deploy this Bicep manually:
// 	 az login
//   az account set --subscription <subscriptionId>
//   az deployment group create -n "manual-$(Get-Date -Format 'yyyyMMdd-HHmmss')" --resource-group rg_dadabase_test --template-file 'main.bicep' --parameters appName=xxx-dad-test environmentCode=test keyVaultOwnerUserId=xxxxxxxx-xxxx-xxxx
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'azd'
param location string = resourceGroup().location
param instanceNumber string = '1'

@description('Deployment type for the web application')
param deploymentType string = 'webapp'  // ['webapp', 'containerapp', 'functionapp', 'all']

param servicePlanName string = ''
param servicePlanResourceGroupName string = '' // if using an existing service plan in a different resource group

param webAppKind string = 'linux' // 'linux' or 'windows'
param webSiteSku string = 'B1'
param webStorageSku string = 'Standard_LRS'
param existingLogAnalyticsWorkspaceName string = ''
param existingLogAnalyticsWorkspaceResourceGroupName string = ''

param azureFoundryResourceUrl string = ''
param azureModelName string = ''

@description('Add Role Assignments for the user assigned identity?')
param addRoleAssignments bool = true

@description('Create a separate user-assigned managed identity. When false, each resource uses its own system-assigned identity.')
param createUserAssignedIdentity bool = false

@description('Add this Admin User Id to KeyVault Access')
param adminUserId string = ''

// calculated variables disguised as parameters
param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var existingServicePlanNameEffective = empty(trim(servicePlanName)) || contains(servicePlanName, '#{') ? '' : trim(servicePlanName)
var existingServicePlanRgNameEffective = empty(trim(servicePlanResourceGroupName)) || contains(servicePlanResourceGroupName, '#{') ? '' : trim(servicePlanResourceGroupName)
var existingLogAnalyticsWorkspaceNameEffective = empty(trim(existingLogAnalyticsWorkspaceName)) || contains(existingLogAnalyticsWorkspaceName, '#{') ? '' : trim(existingLogAnalyticsWorkspaceName)
var existingLogAnalyticsWorkspaceRgNameEffective = empty(trim(existingLogAnalyticsWorkspaceResourceGroupName)) || contains(existingLogAnalyticsWorkspaceResourceGroupName, '#{') ? '' : trim(existingLogAnalyticsWorkspaceResourceGroupName)
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
var deployWebsiteEffective = deployWebAppEffective
var keyVaultApplicationUserObjectIds = deployWebsiteEffective
  ? (createUserAssignedIdentity ? [ webSiteModule!.outputs.userManagedPrincipalId, webSiteModule!.outputs.systemPrincipalId ] : [ webSiteModule!.outputs.systemPrincipalId ])
  : (createUserAssignedIdentity ? [ identity!.outputs.managedIdentityPrincipalId ] : [])
// var resourceToken = toLower(uniqueString(resourceGroup().id, location))

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
module logAnalyticsWorkspaceModule './modules/monitor/loganalyticsworkspace.bicep' = {
  name: 'logAnalytics${deploymentSuffix}'
  params: {
    logAnalyticsWorkspaceName: resourceNames.outputs.logAnalyticsWorkspaceName
    existingLogAnalyticsWorkspaceName: existingLogAnalyticsWorkspaceNameEffective
    existingLogAnalyticsWorkspaceResourceGroupName: existingLogAnalyticsWorkspaceRgNameEffective
    location: location
    commonTags: commonTags
  }
}

// --------------------------------------------------------------------------------
module storageModule './modules/storage/storageaccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageSku: webStorageSku
    storageAccountName: resourceNames.outputs.storageAccountName
    location: location
    commonTags: commonTags
    containerNames: ['input', 'output', 'backup-data', 'joke-images']
  }
}

// --------------------------------------------------------------------------------
module identity './modules/iam/identity.bicep' = if (createUserAssignedIdentity) {
  name: 'appIdentity${deploymentSuffix}'
  params: {
    identityName: resourceNames.outputs.userAssignedIdentityName
    location: location
  }
}

module appRoleAssignments './modules/iam/roleassignments.bicep' = if (addRoleAssignments && createUserAssignedIdentity) {
  name: 'appRoleAssignments${deploymentSuffix}'
  params: {
    identityPrincipalId: identity!.outputs.managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    storageAccountName: storageModule.outputs.name
    keyVaultName:  keyVaultModule.outputs.name
  }
}
// also add rights to the web app storage account (App Service only)
module appRoleAssignments2 './modules/iam/roleassignments.bicep' = if (addRoleAssignments && deployWebAppEffective) {
  name: 'appRoleAssignments-webapp-storage${deploymentSuffix}'
  params: {
    identityPrincipalId: webSiteModule!.outputs.systemPrincipalId
    principalType: 'ServicePrincipal'
    storageAccountName: storageModule.outputs.name
    keyVaultName: keyVaultModule.outputs.name
  }
}

// --------------------------------------------------------------------------------
module keyVaultModule './modules/security/keyvault.bicep' = {
  name: 'keyVault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    location: location
    commonTags: commonTags
    keyVaultOwnerUserId: adminUserId
    adminUserObjectIds: createUserAssignedIdentity ? [ identity!.outputs.managedIdentityPrincipalId ] : []
    applicationUserObjectIds: keyVaultApplicationUserObjectIds
    workspaceId: logAnalyticsWorkspaceModule.outputs.id
    publicNetworkAccess: 'Enabled'
    allowNetworkAccess: 'Allow'
    useRBAC: true
  }
}

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
    appInsightsLocation: location
    commonTags: commonTags
    environmentCode: environmentCode
    webAppKind: webAppKind
    managedIdentityId: effectiveManagedIdentityId
    managedIdentityPrincipalId: effectiveManagedIdentityPrincipalId
    workspaceId: logAnalyticsWorkspaceModule.outputs.id
    appServicePlanName: appServicePlanModule!.outputs.name
    appServicePlanResourceGroupName: appServicePlanModule!.outputs.resourceGroupName
    // In a Linux app service, any nested JSON app key like AppSettings:MyKey needs to be 
    // configured in App Service as AppSettings__MyKey for the key name. 
    // In other words, any : should be replaced by __ (double underscore).
    // NOTE: See https://learn.microsoft.com/en-us/azure/app-service/configure-common?tabs=portal
    customAppSettings: {
      AZURE_CLIENT_ID: effectiveManagedIdentityClientId
      Azure__FoundryResourceUrl: azureFoundryResourceUrl
      Azure__ModelName: azureModelName
      Azure__TokenScope: 'https://ai.azure.com/.default'
    }
  }
}

output SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_NAME string = resourceGroupName
output DEPLOYMENT_TYPE string = deploymentTypeNormalized
output WEB_HOST_NAME string = deployWebAppEffective ? webSiteModule!.outputs.hostName : ''
output WEB_URL string = deployWebAppEffective ? 'https://${webSiteModule!.outputs.hostName}' : ''
output USER_ASSIGNED_IDENTITY_CLIENT_ID string = effectiveManagedIdentityClientId

