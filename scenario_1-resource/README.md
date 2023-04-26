# Bicep Function App Scenario 1 - resource
To be deployed to a resource group  
- Create resource group  
`az group create --name funcAppGroup01 --location eastus`    
- Deploy function app
`az deployment group create --resource-group funcAppGroup01 --template-file main.bicep`
- Delete resource group
`az group delete --resource-group funcAppGroup01`

## Function app  
- Single file
- Config hard coded