# Bicep Function App Scenario 4 - yaml 
To be deployed to a resource group
- Create resource group  
  `az group create --name funcAppGroup04 --location eastus`
- Deploy function app  
  `az deployment group create --resource-group funcAppGroup04 --parameters envConfigType=dev --template-file main.bicep`
- Delete resource group  
  `az group delete --resource-group funcAppGroup04`

## Function app
- Deployed via a .yaml file