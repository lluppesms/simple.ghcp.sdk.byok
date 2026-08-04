// --------------------------------------------------------------------------------
// This BICEP file will create KeyVault secret for a signalR connection
// --------------------------------------------------------------------------------
param keyVaultName string = 'myKeyVault'
param secretName string = 'mySecretName'
param signalRName string = 'mysignalrname'
param enabledDate string = utcNow()
param expirationDate string = dateTimeAdd(utcNow(), 'P2Y')

// --------------------------------------------------------------------------------
resource signalRResource 'Microsoft.SignalRService/SignalR@2022-02-01' existing = { name: signalRName }
var signalRKey = signalRResource.listKeys().primaryKey
var signalRConnectionString = 'Endpoint=https://${signalRName}.service.signalr.net;AccessKey=${signalRKey};Version=1.0;'

// --------------------------------------------------------------------------------
resource keyVaultResource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

@onlyIfNotExists()
resource createSecretValue 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = {
  name: secretName
  parent: keyVaultResource
  properties: {
    value: signalRConnectionString
    attributes: {
      exp: dateTimeToEpoch(expirationDate)
      nbf: dateTimeToEpoch(enabledDate)
    }
  }
}

var createMessage = 'Added secret ${secretName}!'
output message string = createMessage
output secretCreated bool = true
