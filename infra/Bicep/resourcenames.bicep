// --------------------------------------------------------------------------------
// Bicep file that builds all the resource names used by other Bicep templates
// --------------------------------------------------------------------------------
param appName string = ''
param environmentCode string = 'dev'
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
output webSiteName string                = webSiteName
output webSiteAppServicePlanName string  = '${webSiteName}-${resourceAbbreviations.appServicePlanSuffix}'
output userAssignedIdentityName string   = toLower('${sanitizedAppNameInstance}-app-${resourceAbbreviations.managedIdentity}')
