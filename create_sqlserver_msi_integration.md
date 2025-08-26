# Create SQL Server MSI integration

Connect the Jumpbox Virtual Machine through Azure Bastion in Azure Portal. Use the user and password that you defined as the environment variables (e.g., `$JUMPBOX_USER` and `$JUMPBOX_PASSWORD`) at the beginning.

### Steps

- Open Power Shell as administrator in order to install azure client and enable script execution.

    ```powershell
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

    Set-ExecutionPolicy RemoteSigned
    ```
- Execute Script
    - Go to Azure Portal
    - Go to the Azure SQL server
    - On the networking, Selected Networks, and then Add Client IPv4. Save.
    - Then Go to the Azure SQL Database
    - Select Query Editor and Log In using Microsoft Entra authentication
    - Execute the query:
       ```sql
       IF OBJECT_ID('dbo.Counts', 'U') IS NULL 
           CREATE TABLE Counts(
               ID INT NOT NULL IDENTITY PRIMARY KEY, 
               Candidate VARCHAR(32) NOT NULL, 
               Count INT
           );
       ```

- If you chose _standard_ deployment follow these steps to create the SQL command

    ```powershell
    $VOTING_COUNTER_FUNCTION_NAME = $(az deployment group show -g rg-app-service-environments-centralus -n sites --query properties.outputs.votingFunctionName.value -o tsv)
    $VOTING_API_NAME = $(az deployment group show -g rg-app-service-environments-centralus -n sites --query properties.outputs.votingApiName.value -o tsv)

    $SQL = "CREATE USER [$VOTING_COUNTER_FUNCTION_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION_NAME];CREATE USER [$VOTING_API_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API_NAME];"
    ```

- If you chose high _availability_ deployment follow these steps to create the SQL command

    ```powershell
    $VOTING_COUNTER_FUNCTION1_NAME = $(az deployment group show -g rg-app-service-environments-centralus -n sites1 --query properties.outputs.votingFunctionName.value -o tsv)
    $VOTING_COUNTER_FUNCTION2_NAME = $(az deployment group show -g rg-app-service-environments-centralus -n sites2 --query properties.outputs.votingFunctionName.value -o tsv)
    $VOTING_API1_NAME = $(az deployment group show -g rg-app-service-environments-centralus -n sites1 --query properties.outputs.votingApiName.value -o tsv)
    $VOTING_API2_NAME = $(az deployment group show -g rg-app-service-environments-centralus -n sites2 --query properties.outputs.votingApiName.value -o tsv)

    $SQL = "CREATE USER [$VOTING_COUNTER_FUNCTION1_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION1_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION1_NAME];CREATE USER [$VOTING_API1_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API1_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API1_NAME];CREATE USER [$VOTING_COUNTER_FUNCTION2_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_COUNTER_FUNCTION2_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_COUNTER_FUNCTION2_NAME];CREATE USER [$VOTING_API2_NAME] FROM EXTERNAL PROVIDER;ALTER ROLE db_datareader ADD MEMBER [$VOTING_API2_NAME];ALTER ROLE db_datawriter ADD MEMBER [$VOTING_API2_NAME];"
    ```

- Create SQL Server MSI integration

    ```powershell
    # Execute Script in Query Editor
    echo $SQL
    ```

- [Return to README.md](./README.md#set-up-managed-identities-as-users-in-the-sql-database)