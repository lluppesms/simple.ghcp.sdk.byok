// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'azd'
param instanceNumber string = '1'

// --------------------------------------------------------------------------------
var sanitizedEnvironment = toLower(environmentCode)
var sanitizedAppInstanceNameWithDashes = replace(replace(toLower('${appName}${instanceNumber}'), ' ', ''), '_', '')
var sanitizedAppNameInstance = replace(replace(replace(toLower('${appName}${instanceNumber}'), ' ', ''), '_', ''), '-', '')

// --------------------------------------------------------------------------------
// pull resource abbreviations from a common JSON file
var resourceAbbreviations = loadJsonContent('./data/resourceAbbreviations.json')

// --------------------------------------------------------------------------------
var webSiteName = toLower('${sanitizedAppInstanceNameWithDashes}-${sanitizedEnvironment}')

// --------------------------------------------------------------------------------
output logAnalyticsWorkspaceName string  = toLower('${sanitizedAppInstanceNameWithDashes}-${sanitizedEnvironment}-${resourceAbbreviations.logWorkspaceSuffix}')
output webSiteName string                = webSiteName
output webSiteAppServicePlanName string  = '${webSiteName}-${resourceAbbreviations.appServicePlanSuffix}'
output webSiteAppInsightsName string     = '${webSiteName}-${resourceAbbreviations.appInsightsSuffix}'
output userAssignedIdentityName string   = toLower('${sanitizedAppNameInstance}-app-${resourceAbbreviations.managedIdentity}')

// Key Vaults and Storage Accounts can only be 24 characters long
output keyVaultName string               = take('${sanitizedAppNameInstance}${resourceAbbreviations.keyVaultAbbreviation}${sanitizedEnvironment}', 24)
output storageAccountName string         = take('${sanitizedAppNameInstance}${resourceAbbreviations.storageAccountSuffix}${sanitizedEnvironment}', 24)
