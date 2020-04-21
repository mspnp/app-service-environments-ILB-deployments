#!/usr/bin/env bash

# App url
APPGW_APP1_URL=votingapp-std.contoso.com
APPGW_APP2_URL=testapp-std.contoso.com

# IP Addresses
NET_PREFIX=10.0.0.0/16
APPGW_PREFIX=10.0.1.0/24
REDIS_PREFIX=10.0.2.0/24
ASE_PREFIX=10.0.100.0/24
FIREWALL_PREFIX=10.0.200.0/24
JUMPBOX_PREFIX=10.0.250.0/24

# create self-signed SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/CN=${APPGW_APP1_URL}" -out appgw_std.crt -keyout appgw_std.key
openssl pkcs12 -export -out appgw_std.pfx -in appgw_std.crt -inkey appgw_std.key -passout pass:$PFX_PASSWORD
CERT_DATA_1=$(cat appgw_std.pfx | base64 | tr -d '\n' | tr -d '\r')
rm appgw_std.crt appgw_std.key appgw_std.pfx

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/CN=${APPGW_APP2_URL}" -out appgw_std.crt -keyout appgw_std.key
openssl pkcs12 -export -out appgw_std.pfx -in appgw_std.crt -inkey appgw_std.key -passout pass:$PFX_PASSWORD
CERT_DATA_2=$(cat appgw_std.pfx | base64 | tr -d '\n' | tr -d '\r')
rm appgw_std.crt appgw_std.key appgw_std.pfx

# 1. creates the resource group
az group create --name "${RGNAME}" --location "${RGLOCATION}"

# 2. deploy global network related resources
VNET_NAME=$(az network vnet list -g $RGNAME --query "[?contains(addressSpace.addressPrefixes, '${NET_PREFIX}')]" --query [0].name -o tsv)
az group deployment create --resource-group $RGNAME --template-file templates/network.json --parameters existentVnetName=$VNET_NAME vnetAddressPrefix=$NET_PREFIX
VNET_NAME=$(az group deployment show -g $RGNAME -n network --query properties.outputs.vnetName.value -o tsv)
VNET_ROUTE_NAME=$(az group deployment show -g $RGNAME -n network --query properties.outputs.vnetRouteName.value -o tsv)

# 3. deploy ASE
az group deployment create --resource-group $RGNAME --template-file templates/ase.json -n ase --parameters vnetName=$VNET_NAME vnetRouteName=$VNET_ROUTE_NAME aseSubnetAddressPrefix=$ASE_PREFIX
ASE_DNS_SUFFIX=$(az group deployment show -g $RGNAME -n ase --query properties.outputs.dnsSuffix.value -o tsv)
ASE_SUBNET_NAME=$(az group deployment show -g $RGNAME -n ase --query properties.outputs.aseSubnetName.value -o tsv)
ASE_NAME=$(az group deployment show -g $RGNAME -n ase --query properties.outputs.aseName.value -o tsv)
ASE_ID=$(az group deployment show -g $RGNAME -n ase --query properties.outputs.aseId.value -o tsv)
ASE_ILB_IP_ADDRESS=$(az resource show --ids ${ASE_ID}/capacities/virtualip --api-version 2018-02-01 --query internalIpAddress --output tsv)

# Obtain ASE management IP endpoints
ENDPOINTS_LIST=$(az rest --method get --uri $ASE_ID/inboundnetworkdependenciesendpoints?api-version=2016-09-01 | jq '.value[0].endpoints | join(", ")' -j)

# Deploy AF
az group deployment create --resource-group $RGNAME --template-file templates/firewall.json \
    --parameters vnetName=$VNET_NAME firewallSubnetPrefix=$FIREWALL_PREFIX vnetRouteName=$VNET_ROUTE_NAME \
                 aseManagementEndpointsList="$ENDPOINTS_LIST"

# 4. deploy the private DNS zone
az group deployment create --resource-group $RGNAME --template-file templates/dns.json -n dns --parameters vnetName=$VNET_NAME zoneName=$ASE_DNS_SUFFIX ipAddress=$ASE_ILB_IP_ADDRESS

# 5. deploy jumpbox
az group deployment create --resource-group $RGNAME --template-file templates/jumpbox.json --parameters vnetName=$VNET_NAME \
    subnetAddressPrefix=$JUMPBOX_PREFIX adminUsername=$JUMPBOX_USER adminPassword=$JUMPBOX_PASSWORD
JUMPBOX_PUBLIC_IP=$(az group deployment show -g $RGNAME -n jumpbox --query properties.outputs.jumpboxPublicIpAddress.value -o tsv)
JUMPBOX_SUBNET_NAME=$(az group deployment show -g $RGNAME -n jumpbox --query properties.outputs.jumpboxSubnetName.value -o tsv)

# 6. deploy services: cosmos, sql, servicebus and storage
ALLOWED_SUBNET_NAMES=${ASE_SUBNET_NAME},${JUMPBOX_SUBNET_NAME}
az group deployment create --resource-group $RGNAME --template-file templates/services.json \
    --parameters vnetName=$VNET_NAME allowedSubnetNames=$ALLOWED_SUBNET_NAMES \
                 sqlAdminUserName=$SQLADMINUSER sqlAdminPassword=$SQLADMINPASSWORD sqlAadAdminSid=$ADMIN_USER_ID
COSMOSDB_NAME=$(az group deployment show -g $RGNAME -n services --query properties.outputs.cosmosDbName.value -o tsv)
SQL_SERVER=$(az group deployment show -g $RGNAME -n services --query properties.outputs.sqlServerName.value -o tsv)
SQL_DATABASE=$(az group deployment show -g $RGNAME -n services --query properties.outputs.sqlDatabaseName.value -o tsv)
SERVICEBUS_NAME=$(az group deployment show -g $RGNAME -n services --query properties.outputs.serviceBusName.value -o tsv)
KEYVAULT_NAME=$(az group deployment show -g $RGNAME -n services --query properties.outputs.keyVaultName.value -o tsv) 
RESOURCES_STORAGE_ACCOUNT=$(az group deployment show -g $RGNAME -n services --query properties.outputs.resourcesStorageAccountName.value -o tsv)
RESOURCES_CONTAINER_NAME=$(az group deployment show -g $RGNAME -n services --query properties.outputs.resourcesContainerName.value -o tsv)

# Setup the database schema
MY_PUBLIC_IP=$(dig @resolver1.opendns.com ANY myip.opendns.com +short)
az sql server firewall-rule create -g $RGNAME -s $SQL_SERVER -n localip --start-ip-address $MY_PUBLIC_IP --end-ip-address $MY_PUBLIC_IP
sqlcmd -S tcp:${SQL_SERVER}.database.windows.net,1433 -d $SQL_DATABASE -U $SQLADMINUSER -P $SQLADMINPASSWORD -N -l 30 -Q "IF OBJECT_ID('dbo.Counts', 'U') IS NULL CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT);"

# Uploads image to the storage account
az storage blob upload -c $RESOURCES_CONTAINER_NAME -f Microsoft_Azure_logo_small.png -n Microsoft_Azure_logo_small.png --account-name $RESOURCES_STORAGE_ACCOUNT 
RESOURCE_URL="$(az storage account show -n $RESOURCES_STORAGE_ACCOUNT --query primaryEndpoints.blob -o tsv)$RESOURCES_CONTAINER_NAME/Microsoft_Azure_logo_small.png"

# 7. deploy the application services inside the ASE
az group deployment create --resource-group $RGNAME --template-file templates/sites.json -n sites --parameters aseName=$ASE_NAME \
    vnetName=$VNET_NAME redisSubnetAddressPrefix=$REDIS_PREFIX serviceBusName=$SERVICEBUS_NAME cosmosDbName=$COSMOSDB_NAME \
    sqlServerName=$SQL_SERVER sqlDatabaseName=$SQL_DATABASE keyVaultName=$KEYVAULT_NAME \
    aseDnsSuffix=$ASE_DNS_SUFFIX
INTERNAL_APP1_URL=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.votingAppUrl.value -o tsv) && \
INTERNAL_APP2_URL=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.testAppUrl.value -o tsv) && \
VOTING_WEB_APP_PRINCIPAL_ID=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.votingWebAppIdentityPrincipalId.value -o tsv) && \
VOTING_COUNTER_FUNCTION_NAME=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.votingFunctionName.value -o tsv) && \
VOTING_COUNTER_FUNCTION_PRINCIPAL_ID=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.votingCounterFunctionIdentityPrincipalId.value -o tsv) && \
VOTING_API_NAME=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.votingApiName.value -o tsv) && \
VOTING_API_PRINCIPAL_ID=$(az group deployment show -g $RGNAME -n sites --query properties.outputs.votingApiIdentityPrincipalId.value -o tsv)

# Deploy RBAC for resources after AAD propagation
until az ad sp show --id ${VOTING_WEB_APP_PRINCIPAL_ID} &> /dev/null ; do echo "Waiting for AAD propagation" && sleep 5; done
until az ad sp show --id ${VOTING_API_PRINCIPAL_ID} &> /dev/null ; do echo "Waiting for AAD propagation" && sleep 5; done
until az ad sp show --id ${VOTING_COUNTER_FUNCTION_PRINCIPAL_ID} &> /dev/null ; do echo "Waiting for AAD propagation" && sleep 5; done
az group deployment create --resource-group $RGNAME --template-file templates/rbac.json \
    --parameters votingWebAppIdentityPrincipalId=$VOTING_WEB_APP_PRINCIPAL_ID votingCounterFunctionIdentityPrincipalId=$VOTING_COUNTER_FUNCTION_PRINCIPAL_ID \
                 keyVaultName=$KEYVAULT_NAME votingServiceBusNamespace=$SERVICEBUS_NAME

# Generates parameters file for appgw arm script
cat <<EOF > appgwApps.parameters.json
[
  { 
    "name": "votapp", 
    "hostName": "${APPGW_APP1_URL}", 
    "backendAddresses": [ 
      { 
        "fqdn": "${INTERNAL_APP1_URL}" 
      } 
    ], 
    "certificate": { 
      "data": "${CERT_DATA_1}", 
      "password": "${PFX_PASSWORD}" 
    }, 
    "probePath": "/health" 
  },
  { 
    "name": "testapp", 
    "hostName": "${APPGW_APP2_URL}", 
    "backendAddresses": [ 
      { 
        "fqdn": "${INTERNAL_APP2_URL}" 
      } 
    ], 
    "certificate": { 
      "data": "${CERT_DATA_2}", 
      "password": "${PFX_PASSWORD}" 
    }, 
    "probePath": "/"
  }
]
EOF

# 8. deploy the application gateway
az group deployment create --resource-group $RGNAME --template-file templates/appgw.json --parameters vnetName=$VNET_NAME appgwSubnetAddressPrefix=$APPGW_PREFIX appgwApplications=@appgwApps.parameters.json
APPGW_PUBLIC_IP=$(az group deployment show -g $RGNAME -n appgw --query properties.outputs.appGwPublicIpAddress.value -o tsv)

# Removes autogenerated parameter file
rm appgwApps.parameters.json


cat << EOF

NEXT STEPS
---- -----

To finish setting up the managed identities as users in the Sql Database run the following script authenticated as the AAD Admin for the database server

-- script begins
CREATE USER [$VOTING_COUNTER_FUNCTION_NAME] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];
ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];

CREATE USER [$VOTING_API_NAME] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$VOTING_API_NAME];
ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API_NAME];
-- script ends

1) Please, go to azure portal in the resource group: ${RGNAME} and click on **Azure Cosmos Db Account**
then select **cacheContainer** then click on **Documents**. Click on **New Document**.

Replace the whole json payload with below content and click **Save**

{"id": "1", "Message": "Powered by Azure", "MessageType": "AD", "Url": "${RESOURCE_URL}"}


2) If needed, register domain by adding the following record in local host file
    ${APPGW_PUBLIC_IP} ${APPGW_APP1_URL}
    ${APPGW_PUBLIC_IP} ${APPGW_APP2_URL}


3) RDP to ${JUMPBOX_PUBLIC_IP} and the deploy the testing app using the readme instruction


4) Browse to https://${APPGW_APP1_URL} and https://${APPGW_APP2_URL}

EOF
