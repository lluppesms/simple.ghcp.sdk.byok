// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'azd'
param instanceNumber string = '1'
param functionStorageNameSuffix string = 'func'

// --------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentCode)
var sanitizedAppNameWithDashes = replace(replace(toLower(appName), ' ', ''), '_', '')
var sanitizedAppInstanceNameWithDashes = replace(replace(toLower('${appName}${instanceNumber}'), ' ', ''), '_', '')
var sanitizedAppNameInstance = replace(replace(replace(toLower('${appName}${instanceNumber}'), ' ', ''), '_', ''), '-', '')

// --------------------------------------------------------------------------------
// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/resourceAbbreviations.json')

// --------------------------------------------------------------------------------
var webSiteName         = environmentCode == 'prod' ? toLower('${sanitizedAppNameWithDashes}') : toLower('${sanitizedAppInstanceNameWithDashes}-${sanitizedEnvironment}')
var baseStorageName     = toLower('${sanitizedAppNameInstance}${resourceAbbreviations.storageAccountSuffix}${sanitizedEnvironment}')

output functionApp object = {
    appName: 'main'
    name: toLower('${sanitizedAppInstanceNameWithDashes}-${resourceAbbreviations.functionApp}-${sanitizedEnvironment}')
    servicePlanName: toLower('${sanitizedAppInstanceNameWithDashes}-${resourceAbbreviations.functionApp}-${resourceAbbreviations.appServicePlanSuffix}-${sanitizedEnvironment}')
    storageName: take('${baseStorageName}${functionStorageNameSuffix}', 24)
    deploymentStorageContainerName: toLower('app-package-${sanitizedAppInstanceNameWithDashes}-${resourceAbbreviations.functionApp}')
    insightsName: '${sanitizedAppInstanceNameWithDashes}-${resourceAbbreviations.functionApp}-${resourceAbbreviations.appInsightsSuffix}-${sanitizedEnvironment}'
}

// --------------------------------------------------------------------------------
output logAnalyticsWorkspaceName string  = toLower('${sanitizedAppInstanceNameWithDashes}-${sanitizedEnvironment}-${resourceAbbreviations.logWorkspaceSuffix}')
output webSiteName string                = webSiteName
output webSiteAppServicePlanName string  = '${webSiteName}-${resourceAbbreviations.appServicePlanSuffix}'
output webSiteAppInsightsName string     = '${webSiteName}-${resourceAbbreviations.appInsightsSuffix}'
output sqlServerName string              = toLower('${sanitizedAppNameInstance}${resourceAbbreviations.sqlAbbreviation}${sanitizedEnvironment}')

output userAssignedIdentityName string   = toLower('${sanitizedAppNameInstance}-app-${resourceAbbreviations.managedIdentity}')

// Container resources
output containerRegistryName string      = toLower(take('${sanitizedAppNameInstance}${resourceAbbreviations.containerRegistry}${sanitizedEnvironment}', 50))
output containerAppName string           = environmentCode == 'prod' ? toLower('${sanitizedAppNameWithDashes}${resourceAbbreviations.containerApp}') : toLower('${sanitizedAppInstanceNameWithDashes}-${resourceAbbreviations.containerApp}-${sanitizedEnvironment}')
output containerAppsEnvironmentName string = toLower('${sanitizedAppInstanceNameWithDashes}-${resourceAbbreviations.containerAppEnvironment}-${sanitizedEnvironment}')

// Key Vaults and Storage Accounts can only be 24 characters long
output keyVaultName string               = take('${sanitizedAppNameInstance}${resourceAbbreviations.keyVaultAbbreviation}${sanitizedEnvironment}', 24)
output storageAccountName string         = take('${sanitizedAppNameInstance}${resourceAbbreviations.storageAccountSuffix}${sanitizedEnvironment}', 24)
