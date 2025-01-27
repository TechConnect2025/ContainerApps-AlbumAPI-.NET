// The template to create an Azure Application Insights

param name string = 'insights_${uniqueString(resourceGroup().id)}'
param location string = resourceGroup().location
param kind string = 'web'
param applicationType string = 'web'
param requestSource string = 'rest'
param principalIds array = []
param roleDefinitionId string = 'ae349356-3a1b-4a5e-921d-050484c6347e'  // Application Insights Component Contributor
param keyVaultName string = ''
param secretName string = 'myvault/mysecret'


// create the application insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
	name: name
	location: location
	kind: kind
	properties: {
		Application_Type: applicationType
		Request_Source: requestSource
	}
}

// create role assignments for the specified principalIds
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (principalId, index) in principalIds: {
	scope: applicationInsights
	name: guid(applicationInsights.id, principalId, roleDefinitionId, string(index))
	properties: {
		roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
		principalId: principalId
		principalType: 'ServicePrincipal'
	}
}]

// create key vault and secret if keyVaultName is specified
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (keyVaultName != ''){
	name: keyVaultName
}

resource keyVaultSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = if (keyVaultName != ''){
	name: secretName
	parent: keyVault
	properties: {
		attributes: {
			enabled: true
		}
		contentType: 'string'
		value: applicationInsights.properties.ConnectionString
	}
}

output id string = applicationInsights.id
output identityConnectionString string = replace(
	applicationInsights.properties.ConnectionString, 
	applicationInsights.properties.InstrumentationKey, 
	'00000000-0000-0000-0000-000000000000')
output ikeyConnectionString string = applicationInsights.properties.ConnectionString
output keyVaultSecretUri string = (keyVaultName != '' ? keyVaultSecret.properties.secretUriWithVersion : '')
