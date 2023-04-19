# Prepare Jump Box

These steps need to be excuted only once.

RDP into the jumpbox (you can get the IP using AzurePortal). The user and password are the ones that you defined as environment variables at the begining.

# Prerequisites to Run Github Actions Runner

1. Ensure it supports long path names (>260 characters) by setting the GPO
   - Go to Group Policy Editor
   - Computer Configuration -> Administrative Templates -> System -> Filesystem -> Enable Win32 long paths
2. Ensure it has the following software installed
   - Azure CLI
   - GIT

# Set Up Github Actions Variables

On the github repo, set up the following variables:

* FUNCTION_APPPATH - eg. "code/function-app-ri/FunctionApp"
* BUILDCONFIGURATION - eg. "Release"
* FUNCTION_APP_NAME - App Service name for Voting Function App
* VOTINGDATA_APPPATH - eg. "code/web-app-ri/VotingData"
* VOTINGDATA_WEB_APP_NAME - App Service name for Voting API App
* VOTINGWEB_APPPATH - eg. "code/web-app-ri/VotingWeb"
* VOTINGWEB_APP_NAME - App Service name for Voting Web App

# Set Up Github Actions Secret

Obtain AZURE_CREDENTIALS for Github Runner - Copy the output of the following command and paste it in the Github Runner App Secret:
```
az ad sp create-for-rbac --name $ --role contributor \
                                --scopes /subscriptions/$SUBID/resourceGroups/$RGNAME \
                                --sdk-auth
```

# Set Up Github Actions Runner on Jumpbox

1. Navigate to this Github Repository
2. Go to settings
3. Go to Actions > Runners
4. Click on new Self Hosted Runner and follow the instructions on the jumpbox
5. Run each workflow in the .github/workflows directory



[Return to README.md >](./README.md#publish-aspnet-core-web-api-and-function-applications)