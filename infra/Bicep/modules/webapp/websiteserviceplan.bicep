// --------------------------------------------------------------------------------
// This BICEP file will create a Azure App Service Plan or use an existing one
// --------------------------------------------------------------------------------
@description('The name of the app service plan')
param appServicePlanName string = ''
@description('The name of a pre-existing app service plan')
param existingServicePlanName string = ''
@description('The resource group name of a pre-existing app service plan')
param existingServicePlanResourceGroupName string = ''

param location string = resourceGroup().location
param commonTags object = {}
@allowed(['F1','B1','B2','S1','S2','S3'])
param sku string = 'B1'
param webAppKind string = 'linux'

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~website.bicep'}
var tags = union(commonTags, templateTag)
var existingServicePlanRgName = empty(existingServicePlanResourceGroupName) ? resourceGroup().name : existingServicePlanResourceGroupName

// --------------------------------------------------------------------------------

resource existingAppServiceResource 'Microsoft.Web/serverfarms@2024-11-01' existing = if (!empty(existingServicePlanName)) {
  name: existingServicePlanName
  scope: resourceGroup(existingServicePlanRgName)
}

resource appServiceResource 'Microsoft.Web/serverfarms@2024-11-01' = if (empty(existingServicePlanName)) {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: webAppKind
  properties: {
    reserved: webAppKind == 'linux' ? true : false
  }
}
output name string = empty(existingServicePlanName) ? appServiceResource.name : existingAppServiceResource.name
output id string = empty(existingServicePlanName) ? appServiceResource.id : existingAppServiceResource.id
output resourceGroupName string = empty(existingServicePlanName) ? resourceGroup().name : existingServicePlanRgName
