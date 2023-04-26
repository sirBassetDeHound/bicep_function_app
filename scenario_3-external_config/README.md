# Bicep Function App Scenario 3 - External COnfig
To be deployed to a resource group
- Create resource group  
  `az group create --name funcAppGroup03 --location eastus`
- Deploy function app  
  `az deployment group create --resource-group funcAppGroup03 --parameters envConfigType=dev --template-file main.bicep`
- Delete resource group  
  `az group delete --resource-group funcAppGroup03`

## Function app
- Main file defining module
  - Pass params into module
- Params are defined in an external config file