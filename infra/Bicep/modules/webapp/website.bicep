// --------------------------------------------------------------------------------
// This BICEP file will create a Azure Website
// --------------------------------------------------------------------------------
param webSiteName string = ''
param location string = resourceGroup().location
param appInsightsLocation string = resourceGroup().location
param environmentCode string = 'dev'
param commonTags object = {}
param managedIdentityId string = ''
param managedIdentityPrincipalId string = ''

@description('The workspace to store audit logs.')
param workspaceId string = ''

@description('The Name of the service plan to deploy into.')
param appServicePlanName string
param appServicePlanResourceGroupName string = resourceGroup().name
param webAppKind string = 'linux'

@description('Custom application settings to merge with the base settings.')
param customAppSettings object = {}

// --------------------------------------------------------------------------------
var templateTag = { TemplateFile: '~website.bicep'}
var azdTag = environmentCode == 'azd' ? { 'azd-service-name': 'web' } : {}
var tags = union(commonTags, templateTag)
var webSiteTags = union(commonTags, templateTag, azdTag)

// Base app settings that are always applied
var baseAppSettings = {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsResource.properties.InstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsResource.properties.ConnectionString
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
}

// Merge base settings with custom settings
var mergedAppSettings = union(baseAppSettings, customAppSettings)

// --------------------------------------------------------------------------------
var linuxFxVersion = webAppKind == 'linux' ? 'DOTNETCORE|10.0' : '' // 	The runtime stack of web app
var appInsightsName = toLower('${webSiteName}-insights')
var useUserAssignedIdentity = !empty(managedIdentityId)

// --------------------------------------------------------------------------------
resource appInsightsResource 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: appInsightsLocation
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: workspaceId
  }
}

resource appServiceResource 'Microsoft.Web/serverfarms@2024-11-01' existing = {
  name: appServicePlanName
  scope: resourceGroup(empty(appServicePlanResourceGroupName) ? resourceGroup().name : appServicePlanResourceGroupName)
}

resource webSiteResource 'Microsoft.Web/sites@2024-11-01' = {
  name: webSiteName
  location: location
  kind: 'app'
  identity: useUserAssignedIdentity ? {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: { '${managedIdentityId}': {} }
  } : {
    type: 'SystemAssigned'
  }
  tags: webSiteTags
  properties: {
    serverFarmId: appServiceResource.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      alwaysOn: true
      remoteDebuggingEnabled: false
      minimumElasticInstanceCount: 1
      appSettings: [
        { 
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsResource.properties.InstrumentationKey 
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsResource.properties.InstrumentationKey}'
        }
      ]
    }
  }
}

// App Settings Configuration - merges base settings with custom app settings
resource webSiteAppSettingsConfig 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: webSiteResource
  name: 'appsettings'
  properties: mergedAppSettings
}

resource webSiteAppSettings 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: webSiteResource
  name: 'logs'
  dependsOn: [webSiteAppSettingsConfig]
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

// can't seem to get this to work right... tried multiple ways...  keep getting this error:
//    No route registered for '/api/siteextensions/Microsoft.ApplicationInsights.AzureWebSites'.
// resource webSiteAppInsightsExtension 'Microsoft.Web/sites/siteextensions@2020-06-01' = {
//   parent: webSiteResource
//   name: 'Microsoft.ApplicationInsights.AzureWebSites'
//   dependsOn: [ appInsightsResource] or [ appInsightsResource, webSiteAppSettings ]
// }

// resource webSiteMetricsLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${webSiteResource.name}-metrics'
//   scope: webSiteResource
//   properties: {
//     workspaceId: workspaceId
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: true
//         // retentionPolicy: {
//         //   days: 30
//         //   enabled: true 
//         // }
//       }
//     ]
//   }
// }

// https://learn.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs
resource webSiteAuditLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webSiteResource.name}-auditlogs'
  scope: webSiteResource
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AppServiceIPSecAuditLogs'
        enabled: true
        // retentionPolicy: {
        //   days: 30
        //   enabled: true 
        // }
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
        // retentionPolicy: {
        //   days: 30
        //   enabled: true 
        // }
      }
    ]
  }
}

// resource appServiceMetricLogging 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${appServiceResource.name}-metrics'
//   scope: appServiceResource
//   properties: {
//     workspaceId: workspaceId
//     metrics: [
//       {
//         category: 'AllMetrics'
//         enabled: true
//       }
//     ]
//     //    this should be right but it's not supported... :(
//     // logs: [
//     //   {
//     //     category: 'AppRequests'
//     //     enabled: true
//     //   }
//     // ]    
//   }
// }
// output principalId string = webSiteResource.identity.principalId
output name string = webSiteName
output hostName string = webSiteResource.properties.defaultHostName
output systemPrincipalId string = webSiteResource.identity.principalId
output userManagedPrincipalId string = managedIdentityPrincipalId
output appInsightsName string = appInsightsName
output appInsightsKey string = appInsightsResource.properties.InstrumentationKey
output appInsightsConnectionString string = appInsightsResource.properties.ConnectionString
// Note: This will give you a warning saying it's not right, but it will contain the right value!
// output ipAddress string = webSiteResource.properties.inboundIpAddress 
