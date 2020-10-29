# App Service Environment Deployment

## Prerequisites

- [azure-cli](https://docs.microsoft.com/bs-cyrl-ba/cli/azure/install-azure-cli?view=azure-cli-latest)
  2.2.0 or newer.
- [sqlcmd](https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-ver15)
  installed.
- **openssl** tool installed for your platform: `sudo apt-get install openssl`
  or `brew install openssl`
- **jq** tool installed for your platform: `sudo apt-get install jq` or
  `brew install jq`
- **dig** tool installed for your platform: `sudo apt install dnsutils` or
  `brew install bind`
- Check that you are able to get the public IP with `dig`:

  ```bash
  dig @resolver1.opendns.com ANY myip.opendns.com +short
  ```

## Configure AZ CLI

First, Login with the `az` CLI with the following command:

`az login`

After you've logged in, you'll want to select the subscription you want to
deploy this solution into. Get a list of subscriptions with the following
command:

`az account list --output table`

You can then set the subscription you'd like to use with the following command:

`az account set --subscription "The Subscription Name"`

Next, run the `./set_environment_variables.sh` script to set local environment
variables for use with the deployment scripts. This will have you enter Resource
group names, usernames, and other user-specific variables.

## Run a Deployment Script

Change directory to the `deployment` folder:

```bash
cd deployment
```

Then execute either the `deploy_std.sh` or `deploy_ha.sh` for a standard or
high-availability deployment, respectively.

The script will prompt you for various parameters to complete and personalize
the solution deployment, including resource group name, region, and user names
and passwords for generated accounts.

As a note, the region/location should be in the right format. Examples of valid
resource group locations are:

- brazilsouth
- centralus
- eastasia
- eastus
- eastus2
- japaneast
- japanwest
- northcentralus
- northeurope
- southcentralus
- southeastasia
- westeurope
- westus
- westus2

Also, for the SQL Server administrator password, check the
[Password Policy](https://docs.microsoft.com/en-us/sql/relational-databases/security/password-policy?view=sql-server-2017)
requirements.

> **NOTE:** if you're having trouble executing the script, you may need to add
> the execute permission. For example: `chmod +x deploy_std.sh`

## Insert Document in Cosmos DB

1. After deployment ends in the last step, run the following commands to get
   the: resourceURl

   ```bash
   echo "{\"id\": \"1\", \"Message\": \"Powered by Azure\", \"MessageType\": \"AD\", \"Url\": \"${RESOURCE_URL}\"}"
   ```

   The following snippet shows an example of the JSON response:

   ```javascript
   {
     "id": "1",
     "Message": "Powered by Azure",
     "MessageType": "AD",
     "Url": "https://webappri.blob.core.windows.net/webappri/Microsoft_Azure_logo_small.png"
   }
   ```

2. Open Azure portal, navigate to the resource group of the deployment, and
   click on **Azure Cosmos Db Account**.
   - Select **Firewall and virtual network**, there you can see:  
     **Add IP ranges to allow access from the internet or your on-premises
     networks**. Click on **Add my current ip**, and save it.
   - Select **cacheContainer**, then click on **Items**. Click on **New Item**.
     Replace the whole json payload with above content and click **Save**.
   - Go to Azure portal and open the resource group of deployment above. Click
     on **Azure Cosmos Db Account**, then select **Firewall and virtual
     network**, then delete your public ip.

## Register domain by adding a record in hosts file [OPTIONAL]

1. Go to Azure portal, open the the resource group of deployment above, and
   click on **AppGatewayIp**, then copy the IP Address value.
2. Edit local host file.
3. Add a new record using the IP read in step 1 above with the domain defined in
   APPGW_URL.

## Set up managed identities as users in the Sql Database

[Create SQL server MSI Integration](./create_sqlserver_msi_integration.md).

## Publish Asp.net core Web, Api and Function applications

1. [Prepare Jumpbox](./prepare_jumpbox.md).

2. [Compile and Deploy Applications](./compile_and_deploy.md).

3. At this point you should be able to test the application:  
   8.1 For standard deployment, open: https://votingapp-std.contoso.com.  
   8.2 For high availability deployment, open: https://votingapp-ha.contoso.com.

_NOTE: Ignore the certificate validation error on the browser._

This project has adopted the
[Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the
[Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any
additional questions or comments.
