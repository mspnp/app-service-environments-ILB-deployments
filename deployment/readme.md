# Web application Deployment

#### Step 1 Set up the environment variables to run the deployment script.

Run the following commands after providing values for the variables.

**Note:** RGLOCATION should be in the right format. Some examples of valid locations are **westus, eastus, northeurope, westeurope, eastasia, southeastasia, northcentralus, southcentralus, centralus, eastus2, westus2, japaneast, japanwest, brazilsouth**.

```
export RGNAME=yourResourceGroupName
export RGLOCATION=yourLocation
export SQLADMINUSER=yoursqlAdminUser
export JUMPBOX_USER=yourJumpBoxUser
export ADMIN_USER_ID=$(az ad signed-in-user show --query objectId -o tsv)
```

#### Step 2 Enter the password for the sql server administrator and export the variable to be used by the deployment script.
**Note:** Sql administrator has a minimum password size of 8 characters requirement. For sql password requirements Check https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-2017 for Sql administrator password requirements

```
read -s SQLADMINPASSWORD
export SQLADMINPASSWORD
```

#### Step 3 Enter the password for the jumpbox  administrator and export the variable to be used by the deployment script.

```
read -s JUMPBOX_PASSWORD
export JUMPBOX_PASSWORD
```

#### Step 4 Enter the password for the SSL certificate and export the variable to be used by the deployment script.

```
read -s PFX_PASSWORD
export PFX_PASSWORD
```

#### Step 5 Assign execute permissions to the deployment script and run it

*For standard deployment:*
```
chmod +x deploy_std.sh
./deploy_std.sh
```

*For high availability deployment:*
```
chmod +x deploy_ha.sh
./deploy_ha.sh
```

#### Step 6 Insert Document in Cosmos Db
1. After deployment ends in the last step, run below commands to get the resourceURl

```
echo "{\"id\": \"1\", \"Message\": \"Powered by Azure\", \"MessageType\": \"AD\", \"Url\": \"${RESOURCE_URL}\"}"
```

example correct json
```
{"id": "1","Message": "Powered by Azure","MessageType": "AD","Url": "https://webappri.blob.core.windows.net/webappri/Microsoft_Azure_logo_small.png"}
```

2. Go to azure portal in the resource group of deployment above and click on **Azure Cosmos Db Account** then select **cacheContainer** then click on **Documents**. Click on **New Document**. Replace the whole json payload with above content and click **Save**

#### Step 7 Register domain by adding a record in hosts file [OPTIONAL]

1. Go to azure portal in the the resource group of deployment above and click on **AppGatewayIp**, then copy the IP Address value.
2. Edit local host file
3. Add a new record using the IP read in 1) with the domain defined in APPGW_URL

#### Step 8 Publish Asp.net core Web, Api and Function applications.

**Note:** The following steps must be done inside the jumpbox, so first open a RDP connection to it.
**Note:** For HA array make sure to publish all projects in both zones.

1. RDP into the jumpbox (you can get the IP using AzurePortal)

2. Download and Install Git: https://gitforwindows.org/
3. Download VS2019 and Install only ASP.NET component: https://visualstudio.microsoft.com/downloads/
4. Download and Install NodeJs: https://nodejs.org/en/download/

5. Clone the repo in any folder you want (ex: C:\ASE-ILB-RA-RI) and open a cmd prompt:
    5.1 cd C:\ASE-ILB-RA-RI\code\web-app-ri\VotingWeb 
    5.2 npm install -g bower
    5.3 bower install
 
6. Publish:
    6.1. Open Votin.sln solution, right click on VotingData click on **Publish**, select **new profile** then click on **existing**, select the resource group for the deployment select the votingdata api app service deployment.
    6.2. Open VotingWeb.sln,  right click on VotingWeb click on **Publish**, select **new profile** then click on **existing**, select the resource group for the deployment select the votingweb app service deployment.
    6.3. Open FunctionVoteCounter.sln solution right click on VoteCounter project click on **Publish**, select **new profile** then click on **existing**, select the resource group select the function app service deployment.

7. While publishing remember to do it twice for each project if you are using the HA version of the array

8. At this point you should be able to test the application:
    8.1 For standard deployment: https://votingapp-std.contoso.com 
    8.2 For high availability deployment: https://votingapp-ha.contoso.com
    
*NOTE: Ignore the certificate validation error on the browser*
