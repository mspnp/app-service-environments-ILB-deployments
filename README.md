# App Service Environment Deployment

## Prerequisites

- [azure-cli](https://docs.microsoft.com/bs-cyrl-ba/cli/azure/install-azure-cli?view=azure-cli-latest) 2.2.0 or older

* [sqlcmd](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver15) installed

* **jq** tool installed for your platform  
  `sudo apt-get install jq`

* **dig** tool for your platform. Check that you are able to get the public IP.
  Install dig tool  
  `sudo apt install dnsutils`

`dig @resolver1.opendns.com ANY myip.opendns.com +short`

## Set up environment variables to run the deployment script

Run the following commands after providing values for the variables.

**Note:** RGLOCATION should be in the right format. Some examples of valid locations are **westus, eastus, northeurope, westeurope, eastasia, southeastasia, northcentralus, southcentralus, centralus, eastus2, westus2, japaneast, japanwest, brazilsouth**.

```
export RGNAME=yourResourceGroupName
export RGLOCATION=yourLocation
export SQLADMINUSER=yoursqlAdminUser
export JUMPBOX_USER=yourJumpBoxUser
export ADMIN_USER_ID=$(az ad signed-in-user show --query objectId -o tsv)
```

## Enter and export the password for the SQL Server administrator

**Note:** For SQL Server administrator password requirements, check [Password Policy](https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-2017).

```
read -s SQLADMINPASSWORD
export SQLADMINPASSWORD
```

## Enter and export the password for the jumpbox administrator

```
read -s JUMPBOX_PASSWORD
export JUMPBOX_PASSWORD
```

## Enter and export the password for the SSL certificate

```
read -s PFX_PASSWORD
export PFX_PASSWORD
```

## Run the deployment script

Move to templates directory.

```
cd templates
```

Then follow the steps for either standard or high availability deployments.

### For standard deployment

```
chmod +x deploy_std.sh
./deploy_std.sh
```

### For high availability deployment

```
chmod +x deploy_ha.sh
./deploy_ha.sh
```

## Insert Document in Cosmos Db

1. After deployment ends in the last step, run the following commands to get the resourceURl

```
echo "{\"id\": \"1\", \"Message\": \"Powered by Azure\", \"MessageType\": \"AD\", \"Url\": \"${RESOURCE_URL}\"}"
```

The following snippet shows an example of the JSON response:

```
{"id": "1","Message": "Powered by Azure","MessageType": "AD","Url": "https://webappri.blob.core.windows.net/webappri/Microsoft_Azure_logo_small.png"}
```

2. Open Azure portal, navigate to the resource group of the deployment, and click on **Azure Cosmos Db Account**.

- Select **Firewall and virtual network**, there you can see:  
  **Add IP ranges to allow access from the internet or your on-premises networks**. 
  Click on **Add my current ip**, and save it.

- Select **cacheContainer**, then click on **Items**. Click on **New Item**. Replace the whole json payload with above content and click **Save**.

- Go to Azure portal and open the resource group of deployment above. Click on **Azure Cosmos Db Account**, then select **Firewall and virtual network**, then delete your public ip.

## Register domain by adding a record in hosts file [OPTIONAL]

1. Go to Azure portal, open the the resource group of deployment above, and click on **AppGatewayIp**, then copy the IP Address value.
2. Edit local host file.
3. Add a new record using the IP read in step 1 above with the domain defined in APPGW_URL.

## Set up managed identities as users in the Sql Database

[Create SQL server MSI Integration](./create_sqlserver_msi_integration.md).

## Publish Asp.net core Web, Api and Function applications

1. [Prepare Jumpbox](./prepare_jumpbox.md).

2. [Compile and Deploy Applications](./compile_and_deploy.md).

3. At this point you should be able to test the application:  
   8.1 For standard deployment, open: https://votingapp-std.contoso.com.  
   8.2 For high availability deployment, open: https://votingapp-ha.contoso.com.

_NOTE: Ignore the certificate validation error on the browser._


This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
