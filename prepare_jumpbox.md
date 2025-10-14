# Prepare Jump Box

These steps need to be executed only once.

Connect the Jumpbox Virtual Machine through Azure Bastion in Azure Portal. Use the user and password that you defined as the environment variables (e.g., `$JUMPBOX_USER` and `$JUMPBOX_PASSWORD`) at the beginning.

# Prerequisites to Run Github Actions Runner

1. Ensure it supports long path names (>260 characters) by setting the Group Policy Object (GPO)
   - Open the Local Group Policy Editor (gpedit.msc)
   - Computer Configuration -> Administrative Templates -> System -> Filesystem -> Enable Win32 long paths
2. Ensure it has the following software installed

   - Azure CLI
   Open Power Shell as administrator in order to install azure client and enable script execution.

      ```powershell
      Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

      Set-ExecutionPolicy RemoteSigned
      ```

   - Git (https://git-scm.com/downloads)

# Set Up Github Actions Secret

Create and manage user-assigned managed identities to allow GitHub Actions to deploy the apps. The Bicep template also assigns the Contributor role to the resource group and federates the identity to trust on GitHub. [More information here](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect).

```bash
export GITHUB_OWNER=<add your user>
az deployment group create \
  --resource-group rg-app-service-environments-centralus \
  --template-file templates/github-action-identity.bicep \
  --parameters githubOwner=$GITHUB_OWNER
```

Read the results and create github secrets AZURE_CLIENT_ID, AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID.
```bash
export AZURE_CLIENT_ID=$(az deployment group show --resource-group rg-app-service-environments-centralus --name github-action-identity --query "properties.outputs.azureClientId.value" --output tsv)
export AZURE_TENANT_ID=$(az deployment group show --resource-group rg-app-service-environments-centralus --name github-action-identity --query "properties.outputs.azureTenantId.value" --output tsv)
export AZURE_SUBSCRIPTION_ID=$(az deployment group show --resource-group rg-app-service-environments-centralus --name github-action-identity --query "properties.outputs.azureSubscriptionId.value" --output tsv)
echo $AZURE_CLIENT_ID
echo $AZURE_TENANT_ID
echo $AZURE_SUBSCRIPTION_ID
```

# Set Up Github Actions Runner on Jumpbox

1. Navigate to this Github Repository
2. Go to settings
3. Go to Actions > Runners
4. Click on new Self Hosted Runner and follow the instructions on the jumpbox. Keep the Agent Running. Execute the command in a new PowerShell console to take the latest environment variables related to the recently installed tools.

[Return to README.md >](./README.md#ship-publish-aspnet-core-web-api-and-function-applications)