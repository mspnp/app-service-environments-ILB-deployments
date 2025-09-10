@description('The name of the user-assigned managed identity.')
param identityName string = 'github-identity'

@description('The owner of the GitHub repository.')
param githubOwner string

@description('The name of the GitHub repository.')
param githubRepo string = 'app-service-environments-ILB-deployments'

@description('The GitHub environment to restrict the OIDC token to.')
param githubEnvironment string = 'production'

var contributorRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
) // Contributor

@description('The user-assigned managed identity for GitHub Actions.')
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: identityName
  location: resourceGroup().location
}

@description('The role assignment for the user-assigned managed identity.')
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userIdentity.id, resourceGroup().id, 'Contributor')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRole
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The federated identity credentials for the user-assigned managed identity.')
resource federatedCred 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
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

output azureClientId string = userIdentity.properties.clientId
output azureTenantId string = subscription().tenantId
output azureSubscriptionId string = subscription().subscriptionId
