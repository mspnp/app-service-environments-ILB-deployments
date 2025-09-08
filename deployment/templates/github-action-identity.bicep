param identityName string = 'github-identity'
param githubOwner string
param githubRepo string = 'app-service-environments-ILB-deployments'
param githubEnvironment string = 'production'

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: resourceGroup().location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userIdentity.id, 'Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource federatedCred 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'github-federated-cred'
  parent: userIdentity
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:${githubOwner}/${githubRepo}:environment:${githubEnvironment}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

output AZURE_CLIENT_ID string = userIdentity.properties.clientId
output AZURE_TENANT_ID string = subscription().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
