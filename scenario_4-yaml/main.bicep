@description('Function App config')
var environmentConfigurationMap = loadJsonContent('./config/environmentConfigurationMap.json')

@description('Resource group name')
param resourceGroupName string = resourceGroup().name
@description('Resource group location')
param resourceGroupLocation string = resourceGroup().location
@description('Environment config type')
@allowed([
    'production'
    'test'
    'dev'
])
param envConfigType string

var funcAppConfig = environmentConfigurationMap[envConfigType].azFunctionApp
var hostingPlanConfig = environmentConfigurationMap[envConfigType].azHostingPlan
var storageAccountConfig = environmentConfigurationMap[envConfigType].azStorageAccount

module funcAppModule './modules/func_app.bicep' = {
  name: 'funcApp'
  params: {
    location: resourceGroupLocation
    azFunctionAppRuntime: funcAppConfig.node.workerRuntime
    azFunctionAppVersion: funcAppConfig.node.version
    azFunctionAppIdentityType: funcAppConfig.identity.type
    azFunctionAppKind: funcAppConfig.kind
    azFunctionAppClientAffinityEnabled: funcAppConfig.properties.clientAffinityEnabled
    azFunctionAppCors: funcAppConfig.properties.siteConfig.cors.allowedOrigins
    azFunctionHttpsOnly: funcAppConfig.properties.httpsOnly
    azFunctionAppFtpsState: funcAppConfig.properties.siteConfig.ftpsState
    azFunctionAppMinTlsVersion: funcAppConfig.properties.siteConfig.minTlsVersion
    azFunctionAppNetFrameworkVersion: funcAppConfig.properties.siteConfig.netFrameworkVersion
    azFunctionAppUse32BitWorkerProcess: funcAppConfig.properties.siteConfig.use32BitWorkerProcess
    azFunctionAppPublicNetworkAccess: funcAppConfig.properties.publicNetworkAccess
    azHostingPlanConfigSkuName: hostingPlanConfig.sku.name
    azHostingPlanConfigSkuTier: hostingPlanConfig.sku.tier
    azStorageAccountKind: storageAccountConfig.kind
    azStorageAccountSupportsHttpsOnly: storageAccountConfig.properties.supportsHttpsTrafficOnly
    azStorageAccountMinimumTlsVersion: storageAccountConfig.properties.minimumTlsVersion
    azStorageAccountSkuName: storageAccountConfig.sku.name
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: []
}
