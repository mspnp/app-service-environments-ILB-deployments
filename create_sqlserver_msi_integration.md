# Create SQL Server MSI integration

RDP into the jumpbox (you can get the IP using Azure Portal). The user and password are the ones that you defined as environment variables at the begining.

### Steps

- Install [C++ Redistributable](https://learn.microsoft.com/cpp/windows/latest-supported-vc-redist?view=msvc-170) - Download and install the latest supported Visual C++ downloads for x64.

- Install [ODBC Driver 18 for SQL Server](https://learn.microsoft.com/sql/connect/odbc/download-odbc-driver-for-sql-server?view=sql-server-ver17).

- Install [sqlcmd](https://docs.microsoft.com/sql/tools/sqlcmd-utility?view=sql-server-ver15#download-the-latest-version-of-sqlcmd-utility).

- Open Power Shell as administrator in order to install azure client and enable script execution.

    ```powershell
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

    Set-ExecutionPolicy RemoteSigned
    ```

- Open a new PowerShell console and follow the next steps.

- Create the "Counts" table.

    ```powershell
    $RGNAME = '[YOUR RESOURCE GROUP NAME]'
    $USER = '[YOUR AZURE ACCOUNT]'

    az login
    $SQL_SERVER = $(az deployment group show -g $RGNAME -n services --query properties.outputs.sqlServerName.value -o tsv)
    $SQL_DATABASE = $(az deployment group show -g $RGNAME -n services --query properties.outputs.sqlDatabaseName.value -o tsv)

    $SQL_TABLE_OBJECT = "IF OBJECT_ID('dbo.Counts', 'U') IS NULL CREATE TABLE Counts(ID INT NOT NULL IDENTITY PRIMARY KEY, Candidate VARCHAR(32) NOT NULL, Count INT);"


    $accessToken = az account get-access-token --resource https://database.windows.net --query accessToken -o tsv

    $env:SQLCMDACCESSTOKEN = $accessToken

    sqlcmd -S tcp:$SQL_SERVER.database.windows.net,1433 -d $SQL_DATABASE  -Q $SQL_TABLE_OBJECT -G
    ```

- If you chose _standard_ deployment follow these steps to create the SQL command

    ```powershell
    $VOTING_COUNTER_FUNCTION_NAME = $(az deployment group show -g $RGNAME -n sites --query properties.outputs.votingFunctionName.value -o tsv)
    $VOTING_API_NAME = $(az deployment group show -g $RGNAME -n sites --query properties.outputs.votingApiName.value -o tsv)

    $SQL = "CREATE USER [$VOTING_COUNTER_FUNCTION_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];CREATE USER [$VOTING_API_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API_NAME];"
    ```

- If you chose high _availability_ deployment follow these steps to create the SQL command

    ```powershell
    $VOTING_COUNTER_FUNCTION1_NAME = $(az deployment group show -g $RGNAME -n sites1 --query properties.outputs.votingFunctionName.value -o tsv)
    $VOTING_COUNTER_FUNCTION2_NAME = $(az deployment group show -g $RGNAME -n sites2 --query properties.outputs.votingFunctionName.value -o tsv)
    $VOTING_API1_NAME = $(az deployment group show -g $RGNAME -n sites1 --query properties.outputs.votingApiName.value -o tsv)
    $VOTING_API2_NAME = $(az deployment group show -g $RGNAME -n sites2 --query properties.outputs.votingApiName.value -o tsv)

    $SQL = "CREATE USER [$VOTING_COUNTER_FUNCTION1_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION1_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION1_NAME];CREATE USER [$VOTING_API1_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API1_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API1_NAME];CREATE USER [$VOTING_COUNTER_FUNCTION2_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION2_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION2_NAME];CREATE USER [$VOTING_API2_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API2_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API2_NAME];"
    ```

- Create SQL Server MSI integration

    ```powershell
    sqlcmd -S tcp:$SQL_SERVER.database.windows.net,1433 -d $SQL_DATABASE -N -l 30 -G -Q $SQL
    ```

- [Return to README.md](./README.md#set-up-managed-identities-as-users-in-the-sql-database)