# Prepare Jump Box

These steps need to be excuted only once.

RDP into the jumpbox (you can get the IP using AzurePortal). The user and password are the ones that you defined as environment variables at the begining.

## Windows Linux Subsystem

- Open Power shell, and enable [Windows Linux Subsystem](https://docs.microsoft.com/en-us/windows/wsl/install-win10):

  ```
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux​1
  ```

  You will need to restart the computer. 

- Log in the VM again. Open the Microsoft Store, then search WSL, choose Ubuntu, and install it.

- Follow [these instructions](https://docs.microsoft.com/windows/wsl/install-on-server) to install WSL on your jumpbox. Since you are using
  Windows Server 2019 you will need to skip the Windows Store part (not available in WS 2019) and download ubuntu directly from [this link](https://docs.microsoft.com/windows/wsl/install-manual#downloading-distributions).

- Open WSL Ubuntu. When prompted, enter admin user and password. Then execute this command:

  ```
  sudo apt-get update 
  ```

## Azure CLI

On command line, execute the following command to install [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest):

```
 curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
 az login
```

## Software dependencies

The following software packages are required:

- nodejs
- npm
- bower
- zip
- .Net 5

Run the following commands to install the above dependencies:

```
sudo apt-get install nodejs
sudo apt install npm
sudo npm install -g bower
sudo apt install zip
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-3.1
sudo apt-get install dotnet-sdk-5.0
```

## Download source code

Clone the code from the git repository.

```
git clone https://github.com/mspnp/app-service-environments-ILB-deployments.git
```