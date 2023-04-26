@description('Function App config')
var environmentConfigurationMap = {
    azFunctionApp: {
        identity: {
            type: 'SystemAssigned'
        }
        kind: 'functionapp'
        node: {
            workerRuntime: 'node'
            version: '~18'
        }
        properties: {
            clientAffinityEnabled: false
            httpsOnly: true
            publicNetworkAccess: 'Enabled'
            siteConfig: {
                cors: {
                    allowedOrigins: ['*']
                }
                ftpsState: 'FtpsOnly'
                minTlsVersion: '1.2'
                netFrameworkVersion: 'v6.0'
                use32BitWorkerProcess: true
            }
        }
    }
    azHostingPlan: {
        kind: 'windows'
        sku: {
            name: 'Y1'
            tier: 'Dynamic'
        }
    }
    azStorageAccount: {
        kind: 'StorageV2'
        properties: {
            supportsHttpsTrafficOnly : true
            minimumTlsVersion: 'TLS1_2'
        }
        sku: {
            name: 'Standard_LRS'
        }
    }
}

@description('Resource group name')
param resourceGroupName string = resourceGroup().name
@description('Resource group location')
param resourceGroupLocation string = resourceGroup().location

var funcAppConfig = environmentConfigurationMap.azFunctionApp
var hostingPlanConfig = environmentConfigurationMap.azHostingPlan
var storageAccountConfig = environmentConfigurationMap.azStorageAccount

module funcAppModule './func_app.bicep' = {
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
