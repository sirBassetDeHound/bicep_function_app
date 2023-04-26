# Bicep Function App Scenario 2 - Modules
To be deployed to a resource group
- Create resource group  
  `az group create --name funcAppGroup02 --location eastus`
- Deploy function app  
  `az deployment group create --resource-group funcAppGroup02 --template-file main.bicep`
- Delete resource group  
  `az group delete --resource-group funcAppGroup02`

## Function app
- Main file defining module
  - Pass params into module
- Config mapping included at top of main file