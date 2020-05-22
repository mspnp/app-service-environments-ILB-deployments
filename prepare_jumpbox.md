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
- .Net Core 3.1

Run the following commands to install the above dependencies:

```
sudo apt-get install nodejs
sudo apt install npm
sudo npm install -g bower
sudo apt install zip
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-3.1
```

## Download source code

Clone the code from the git repository.
