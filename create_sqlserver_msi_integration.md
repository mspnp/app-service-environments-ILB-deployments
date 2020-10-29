# Create SQL Server MSI integration

These steps need to be excuted only once.

RDP into the jumpbox (you can get the IP using AzurePortal). The user and
password are the ones that you defined as environment variables at the begining.

## Steps

- Install
  [C++ Redistributable](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-download) -
  Download and install the latest supported Visual C++ downloads for x64.

- Install
  [ODBC Driver 17 for SQL Server](https://www.microsoft.com/en-us/download/details.aspx?id=56567).

- Install
  [sqlcmd](https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility?view=sql-server-ver15#download-the-latest-version-of-sqlcmd-utility).

- Open Power Shell as administrator in order to install azure client and enable
  script execution.

```powershell
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi

Set-ExecutionPolicy RemoteSigned
```

- Open a new PowerShell console and run a PowerShell script - choose standard or
  high availability deployment as per your scenario.

```powershell
.\sqlserver_msi_std.ps1   **Your resource group**  **your azure account name**
```

or

```powershell
.\sqlserver_msi_ha.ps1  **Your resource group**  **your azure account name**
```
