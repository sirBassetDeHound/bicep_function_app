@description('Resource location from main.bicep params')
param location string
@description('Storage account sku')
param azStorageAccountSkuName string
@description('Storage account kind')
param azStorageAccountKind string
@description('Storage account support Https only')
param azStorageAccountSupportsHttpsOnly bool
@description('Storage account minimum Tls Version')
param azStorageAccountMinimumTlsVersion string
@description('Function app identity type')
param azFunctionAppIdentityType string
@description('Function app kind')
param azFunctionAppKind string
@description('The language worker runtime to load in the function app.')
param azFunctionAppRuntime string
@description('Function app runtime version')
param azFunctionAppVersion string
@description('Function app cors policy allow all')
param azFunctionAppCors array
@description('Function app ftps state')
param azFunctionAppFtpsState string
@description('Function app net framework version')
param azFunctionAppNetFrameworkVersion string
@description('Function app min TLS version')
param azFunctionAppMinTlsVersion string
@description('Function app public network access')
param azFunctionAppPublicNetworkAccess string
@description('Function app https only')
param azFunctionHttpsOnly bool
@description('Function app use 32 bit worker process')
param azFunctionAppUse32BitWorkerProcess bool
@description('Function app client affinity enabled')
param azFunctionAppClientAffinityEnabled bool
@description('Hosting plan sku name')
param azHostingPlanConfigSkuName string
@description('Hosting plan sku tier')
param azHostingPlanConfigSkuTier string

var storageAccountName = 'azapp${uniqueString(resourceGroup().id)}'
var functionAppName = 'azfun${uniqueString(resourceGroup().id)}'

@description('Storage account')
resource azStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name:  storageAccountName
  location: location
  kind: azStorageAccountKind
  sku: {
    name: azStorageAccountSkuName
  }
  properties: {
    supportsHttpsTrafficOnly: azStorageAccountSupportsHttpsOnly
    minimumTlsVersion: azStorageAccountMinimumTlsVersion
  }
}

@description('App service plan')
resource azHostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'host${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: azHostingPlanConfigSkuName
    tier: azHostingPlanConfigSkuTier
  }
}

@description('Function app')
resource azFunctionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: azFunctionAppKind
  identity: {
    type: azFunctionAppIdentityType
  }
  properties: {
    httpsOnly: azFunctionHttpsOnly
    publicNetworkAccess: azFunctionAppPublicNetworkAccess
    serverFarmId: azHostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${azStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${azStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: azFunctionAppRuntime
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: azFunctionAppVersion
        }
      ]
      cors: {
        allowedOrigins: azFunctionAppCors
      }
      ftpsState: azFunctionAppFtpsState
      minTlsVersion: azFunctionAppMinTlsVersion
      netFrameworkVersion: azFunctionAppNetFrameworkVersion
      use32BitWorkerProcess: azFunctionAppUse32BitWorkerProcess
    }
    clientAffinityEnabled: azFunctionAppClientAffinityEnabled
    virtualNetworkSubnetId: null
  }
}
