# Compile and Deploy

 RDP into the jumpbox (you can get the IP using AzurePortal). The user and password are the ones that you defined as environment variables at the begining.​

 The [jumpbox need to be intializated](./prepare_jumpbox.md) is required
​
## Precondition

* Open Ububtu (WSL) on your JumpBox

* Set the resource group used to deploy the ASE

```​
export RGNAME=**The deployed resource group**​
```

* Move to code directory

```
cd ASE-ILB-RA-RI/code​
```

##  Compile Applications

```​
dotnet publish -c Release -o deploy/VotingData web-app-ri/VotingData/VotingData.csproj​
pushd deploy/VotingData/ && zip -r ../VotingData.zip * && popd​
 ​
dotnet publish -c Release -o deploy/VoteCounter function-app-ri/FunctionApp/VoteCounter.csproj​
pushd deploy/VoteCounter/ && zip -r ../VoteCounter.zip * && popd​
 ​
pushd web-app-ri/VotingWeb/ && bower install && popd​
dotnet publish -c Release -o deploy/VotingWeb web-app-ri/VotingWeb/VotingWeb.csproj​
pushd deploy/VotingWeb/ && zip -r ../VotingWeb.zip * && popd​  
```

##  Deploy Applications

The  application must be compiled.

### Standard Deploy
```​
export WEBAPP_NAME=$(az deployment group  show -g $RGNAME -n sites --query properties.outputs.votingWebName.value -o tsv) && export WEBAPI_NAME=$(az deployment group  show -g $RGNAME -n sites --query properties.outputs.votingApiName.value -o tsv) && export FUNCTION_NAME=$(az deployment group  show -g $RGNAME -n sites --query properties.outputs.votingFunctionName.value -o tsv) ​
 ​
az webapp deployment source config-zip --name $WEBAPI_NAME --resource-group $RGNAME --src deploy/VotingData.zip​
 ​
az functionapp deployment source config-zip --name $FUNCTION_NAME --resource-group $RGNAME --src deploy/VoteCounter.zip​
 ​
az webapp deployment source config-zip --name $WEBAPP_NAME --resource-group $RGNAME --src deploy/VotingWeb.zip​
```

### HA Deploy

```
# ASE1
export WEBAPP_NAME1=$(az deployment group  show -g $RGNAME -n sites1 --query properties.outputs.votingWebName.value -o tsv) && export WEBAPI_NAME1=$(az deployment group  show -g $RGNAME -n sites1 --query properties.outputs.votingApiName.value -o tsv) && export FUNCTION_NAME1=$(az deployment group  show -g $RGNAME -n sites1 --query properties.outputs.votingFunctionName.value -o tsv) ​
 ​
az webapp deployment source config-zip --name $WEBAPI_NAME1 --resource-group $RGNAME --src deploy/VotingData.zip​
 ​
az functionapp deployment source config-zip --name $FUNCTION_NAME1 --resource-group $RGNAME --src deploy/VoteCounter.zip​
 ​
az webapp deployment source config-zip --name $WEBAPP_NAME1 --resource-group $RGNAME --src deploy/VotingWeb.zip​
​
​# ASE2
export WEBAPP_NAME2=$(az deployment group  show -g $RGNAME -n sites2 --query properties.outputs.votingWebName.value -o tsv) && export WEBAPI_NAME2=$(az deployment group  show -g $RGNAME -n sites2 --query properties.outputs.votingApiName.value -o tsv) && export FUNCTION_NAME2=$(az deployment group  show -g $RGNAME -n sites2 --query properties.outputs.votingFunctionName.value -o tsv) ​
 ​
az webapp deployment source config-zip --name $WEBAPI_NAME2 --resource-group $RGNAME --src deploy/VotingData.zip​
 ​
az functionapp deployment source config-zip --name $FUNCTION_NAME2 --resource-group $RGNAME --src deploy/VoteCounter.zip​
 ​
az webapp deployment source config-zip --name $WEBAPP_NAME2 --resource-group $RGNAME --src deploy/VotingWeb.zip
```