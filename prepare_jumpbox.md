# Prepare Jump Box

These steps need to be excuted only once.

Connect the Jumpbox Virtual Machine through Azure Bastion in Azure Portal. Use the user and password that you defined as the environment variables (e.g., `$JUMPBOX_USER` and `$JUMPBOX_PASSWORD`) at the beginning.

# Prerequisites to Run Github Actions Runner

1. Ensure it supports long path names (>260 characters) by setting the Group Policy Object (GPO)
   - Open the Local Group Policy Editor (gpedit.msc)
   - Computer Configuration -> Administrative Templates -> System -> Filesystem -> Enable Win32 long paths
2. Ensure it has the following software installed
   - Azure CLI (it was already installed on Create SQL Server MSI integration)
   - Git

# Set Up Github Actions Variables

1. Go to your repository on GitHub.
2. Click on Settings.
3. In the left sidebar, click Variables under the Secrets and variables section.
4. Click Actions.
5. Click New variable.
6. Set up the following variables

* FUNCTION_APPPATH - eg. "code/function-app-ri/FunctionApp"
* BUILDCONFIGURATION - eg. "Release"
* FUNCTION_APP_NAME - App Service name for Voting Function App
* VOTINGDATA_APPPATH - eg. "code/web-app-ri/VotingData"
* VOTINGDATA_WEB_APP_NAME - App Service name for Voting API App
* VOTINGWEB_APPPATH - eg. "code/web-app-ri/VotingWeb"
* VOTINGWEB_APP_NAME - App Service name for Voting Web App

# Set Up Github Actions Secret

Obtain AZURE_CREDENTIALS for Github Runner - Copy the output of the following command and paste as secret:

```bash
az ad sp create-for-rbac --name "votingapp-service-principal" --role contributor \
                                --scopes /subscriptions/$SUBID/resourceGroups/$RGNAME \
                                --sdk-auth
```

# Set Up Github Actions Runner on Jumpbox

1. Navigate to this Github Repository
2. Go to settings
3. Go to Actions > Runners
4. Click on new Self Hosted Runner and follow the instructions on the jumpbox amd keep the Agent Running

[Return to README.md >](./README.md#publish-aspnet-core-web-api-and-function-applications)