# Prepare Jump Box

Activites to be excuted once

RDP into the jumpbox (you can get the IP using AzurePortal). The user and password are the ones that you defined as environment variables at the begining.​

### [Enable Windows Linux Subsystem](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

- Open Power shell ​

```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux​1
```

- Restart the computer will be required ​

- Log in the VM again​

- Open the Microsoft Store, then search WSL and choose ubuntu and install it​
  ​
- Open WSL Ubuntu. It will take some time and you must enter admin user and pass ​

- Execute

```
sudo apt-get update  ​
```

### [Azure Client](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)

Please execute:

```
 curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  ​
 az login​
```

### Software Dependencies

It is required:

- nodejs
- npm
- bower
- zip
- .Net Core 3.1

Execute:

```
​sudo apt-get install nodejs​
sudo apt install npm
sudo npm install -g bower​​
sudo apt install zip
wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-3.1
```

### Download source code

Clone the code from the git repository
