---
title:Developing Azure functions using reusable Bicep modules
posted:https://dev.to/danwright/developing-azure-functions-using-reusable-bicep-modules-3nb6
dated:April-24-2023
---

# Developing Azure functions using reusable Bicep modules


## The benefits of infrastructure as code
Infrastructure as code (IaC) is the practice of a creating a model in code to generate an identical environment each time it is run, reducing human error, enforcing business best practice, and allowing teams that use it to innovate and deploy needed infrastructure faster and safer than manually generating the resources when needed. IaC is a fundamental concept utilizing DevOps methodologies to automate the validation, build and deployment of infrastructure in a way that closes the gap between development teams and IT operations teams. 
Using IaC we can ensure that environments created are appreciative of cost, using environment config, reusable, using modules, and require minimal human input, using CI/CD or cmd line deployment. With this approach we can be confident that teams wishing to use our templates can do so in a business approved way giving them confidence to take innovation into the cloud or rapidly deploy new infrastructure to an existing environment.

## Azure Resource Manager (ARM) templates
ARM templates are JSON files that define the deployment resources and variables. They can be used to create azure resources in a declarative modular way that provides built in validation and the ability to preview changes. The template contains a schema to determine the version and language, properties, variables, function, resources, and outputs.
```
{
  "$schema": "https://schema.management.azure.com/schemas/...
  "contentVersion": "",
  "apiProfile": "",
  "parameters": {  },
  "variables": {  },
  "functions": [  ],
  "resources": [  ],
  "outputs": {  }
}

```
When using the Azure portal to create a resource these templates can be found at the ‘Review + Create’ stage under the ‘Download a template for automation’ link at the bottom.

## Bicep
Bicep is Microsoft’s domain-specific language (DSL) used to deploy Azure resources in a declarative modular way. Additionally, like ARM templates they can be used with what-if operations to preview the impact the deployment will have. Unlike ARM templates Bicep syntax is less verbose and defines simpler syntax for writing parameters and conditional operators among others and introduces annotations including @describe and @secure.

## Azure CLI (Command Line Interface)
The Azure CLI is the simplest way to work with ARM or Bicep files and most notably can be used to:
Decompile a Bicep file or files from an ARM templates - 
`az bicep decompile –file {ARM_TEMPLATE_NAME.json}`
Build an ARM template from a Bicep file - 
`az bicep build –file {BICEP_FILE_NAME.bicep}`
Deploy bicep to a resource group - 
`az deployment group create –name {RESOURCE_GROUP_NAME} –file {BICEP_FILE_NAME.bicep}`

## Azure Functions
Azure functions provide a platform for developers to build and deploy application logic in a way that does not require them to maintain the underlying infrastructure required to run them. Azure functions build on the principles of serverless computing by providing on-demand compute allowing consumers to meet changing demand whilst paying only for what they use.

Azure Functions is a Function as a service (FaaS) and to be deployed will require:
* **storage account** - Used to store app data, potentially app code, and will be used to manage operations including triggers and logging function executions.
* **hosting plan** - Used to define resources available and how the function is scaled.
* **function definition** - Used to define the function runtime amongst other app config


## Creating a functions resource file
In order to run the bicep file a resource group needs to be created. To do this via the cmd line:
```
az group create --name rgfunappdev001 --location eastus
```
The resource group name should follow best practice naming:
```
rg-<app or service name>-<subscription purpose>-<###>
```

### Creating a storage account:
```
@description('Storage account')
resource azStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name:  'azapp${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}
```

### Creating a hosting plan:
```
@description('App service plan')
resource azHostingPlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'host${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}
```


### Creating a function:
```
@description('Function app')
resource azFunctionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'azfun${uniqueString(resourceGroup().id)}'
  location: resourceGroup().location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
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
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
      ]
      cors: {
        allowedOrigins: ['*']
      }
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      netFrameworkVersion: 'v6.0'
      use32BitWorkerProcess: true
    }
    clientAffinityEnabled: false
    virtualNetworkSubnetId: null
  }
}
```
Using bicep files with config hard-coded into the resources means that the file will only ever deploy that instance of the resource. Having the resource only able to do 1 specific task reduces its reusability, and, increases the need for alterations based on differing need, introducing the potential for error and not adhering to company best practice and cost. If the user wishes to deploy more than this single file, they will need to make multiple deployments, causing them to ensure they correctly deploy resources dependent on others to reduce the risk of deployment failures.

## Externalizing config

The aim of decoupling the config from the resource allows the resource to be reused for differing deployment variations based on user requirements. Doing so means that config and infrastructure policy can be maintained and controlled independently of the resource creator.

External JSON files can be loaded into the ./main.bicep file and then passed into the resource.
```
@description('Function App config')
var environmentConfigurationMap = loadJsonContent('./environmentConfigurationMap.json')
```

environmentConfigMap.json
```
{
	"production": {},
	"test": {},
	"dev": {
		"azFunctionApp": {
			"identity": {
				"type": "SystemAssigned"
			},
			"kind": "functionapp",
			"node": {
				"workerRuntime": "node",
				"version": "~18"
			},
			"properties": {
				"clientAffinityEnabled": false,
				"httpsOnly": true,
				"publicNetworkAccess": "Enabled",
				"siteConfig": {
					"cors": {
						"allowedOrigins": [
							"*"
						]
					},
					"ftpsState": "FtpsOnly",
					"minTlsVersion": "1.2",
					"netFrameworkVersion": "v6.0",
					"use32BitWorkerProcess": true
				}
			}
		},
		"azHostingPlan": {
			"kind": "windows",
			"sku": {
				"name": "Y1",
				"tier": "Dynamic"
			}
		},
		"azStorageAccount": {
			"kind": "StorageV2",
			"properties": {
				"supportsHttpsTrafficOnly" : true,
				"minimumTlsVersion": "TLS1_2"
			},
			"sku": {
				"name": "Standard_LRS"
			}
		}
	}
}
```

To ensure that the correct environment config is used the '–parameters' flag can be passed into the cmd line instruction and used within the main.bicep file as a param.

```
`az deployment sub create --location 'centralus' --parameters 
 environmentType=dev --template-file ./main.bicep`
```

```
@description('env config types')
@allowed([
  'production'
  'test'
  'dev'
])
param environmentType string
```

The @allowed annotation will cause the bicep build to throw an error if a parameter is provided that is not allowed, it also notifies the user of the intended expected options. A user could easily use this template to provision a dev, test or production environment but could not use it if they wanted a UAT environment.

## Reusable resources

To make the function app resource defined in the ./main.bicep file reusable it can be externalized into its own file, './funcationApp.bicep'. 
This file will no longer have direct access to the config which it needs to define the resources but rather have them passed into the file as params that can have their type and name defined at the top of the file.

Using the storage account (azStorageAccount) defined previously, it and its params will look like: 
```
@description('Storage account sku')
param azStorageAccountSkuName string
@description('Storage account kind')
param azStorageAccountKind string
@description('Storage account support Https only')
param azStorageAccountSupportsHttpsOnly bool
@description('Storage account minimum Tls Version')
param azStorageAccountMinimumTlsVersion string

@description('Storage account')
resource azStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name:  'azapp${uniqueString(resourceGroup().id)}'
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
```

This process can be then done for each of additional resources that are defined to complete the function app. 

## Modules 

Once the config has been externalized and there is a way to select the relevant environment config options, update the ./main.bicep file to include a module which encapsulates the resource to be deployed. This means that our main.bicep file will be easier to read and offer a way to template the deployment of our resources.

Using the azStorageAccount the module will look like:
```
module funcAppModule './funcationApp.bicep' = {
name: 'funcApp'
  params: {
    location: resourceGroupLocation
    azStorageAccountKind: storageAccountConfig.kind
    azStorageAccountSupportsHttpsOnly: storageAccountConfig.properties.supportsHttpsTrafficOnly
    azStorageAccountMinimumTlsVersion: storageAccountConfig.properties.minimumTlsVersion
    azStorageAccountSkuName: storageAccountConfig.sku.name
    ...azHostingPlanParams
    ...azFunctionAppParams 
  }
  scope: resourceGroup(resourceGroupName)
  dependsOn: []
}
```

## Conclusion

Once completed the config used to define the values for the properties of the resources to be deployed will be contained in a .json file that can be managed and maintained by DevOps teams who understand the business best practices around deployments, costs, and naming conventions. The function app resource will now be in a separate file containing all the properties needed to create the resource but will be decoupled from any deployment config values, allowing it to be reused for any given number of deployments. The ./main.bicep file used for deploying the resource will define the parameters needed to be passed in via the cmd line and will be responsible for providing the resource with the correct config. Using this approach, dev teams can have a faster reproducible, approach to deploying needed resources that can be business approved and deployed via an automated pipeline.





