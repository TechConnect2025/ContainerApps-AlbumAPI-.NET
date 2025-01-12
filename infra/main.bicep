// The templates are generated by bicep IaC generator
targetScope = 'subscription'

param location string = 'eastus'
param environmentName string = 'myenv'
param resourceGroupName string = 'rg-myenv'
param resourceToken string = toLower(uniqueString(subscription().id, location, resourceGroupName))
param containerAppSrcName string = 'src${resourceToken}'
param keyVaultKeyvault0Name string = 'keyvault0${resourceToken}'
param containerAppEnvName string = 'env${resourceToken}'
param containerRegistryName string = 'acr${resourceToken}'


// Deploy an Azure Resource Group

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
	name: resourceGroupName
	location: location
	tags: { 'azd-env-name': environmentName }
}

// Deploy an Azure Container App environment

module containerAppEnv 'containerappenv.bicep' = {
	name: 'container-app-env-deployment'
	scope: resourceGroup
	params: {
		location: location
		name: containerAppEnvName
	}
}
var containerAppEnvId = containerAppEnv.outputs.id

// Deploy an Azure Container Registry

module containerRegistry 'containerregistry.bicep' = {
	name: 'container-registry-deployment'
	scope: resourceGroup
	params: {
		location: location
		name: containerRegistryName
	}
}

// Deploy an Azure Container App

module containerAppSrcDeployment 'containerapp.bicep' = {
	name: 'container-app-src-deployment'
	scope: resourceGroup
	params: {
		location: location
		name: containerAppSrcName
		targetPort: 8080 
		containerAppEnvId: containerAppEnvId
		identityType: 'SystemAssigned'
		containerRegistryName: containerRegistryName  
		tags: {'azd-service-name': 'src'}
	}
	dependsOn: [
		containerAppEnv
		containerRegistry
	]
}

// Deploy an Azure Keyvault

module keyVaultKeyvault0Deployment 'keyvault.bicep' = {
	name: 'key-vault-keyvault0-deployment'
	scope: resourceGroup
	params: {
		location: location
		name: keyVaultKeyvault0Name 
	}
}



output containerAppSrcId string = containerAppSrcDeployment.outputs.id
output keyVaultKeyvault0Id string = keyVaultKeyvault0Deployment.outputs.id
output containerRegistrySrcId string = containerRegistry.outputs.id
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

