### Prerequisites

1. deploy the Reference Implementation
2. remote to the Jumpbox
3. Azure DevOps organization
4. create a new Agent Pool and add a new self hosted agent

   > note: follow the Windows powershell instructions to add a self hosted agent in your jumpbox.
   > For more information, please take a look at https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=browser#install

5. ensure your Azure Subscription has been added to the Azure Pipelines service connections

### Instructions

1. create new Azure Pipeline from existing yaml and indicate the path `code/web-app-ri/VotingData/azure-pipelines.yml`
2. add the following variables:
   - poolName # name you've choosen from pre-requistes step 4
   - azureSubscription
   - webAppNameZone1
   - webAppNameZone3
3. run pipeline

   > note: first time will ask for authorize the Azure Subscrition to be used
   > from the pipeline

