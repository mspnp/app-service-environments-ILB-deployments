# Introduction 
App Services Environment has two configurations, [external]( /azure/app-service/environment/create-external-ase) and [internal]( /azure/app-service/environment/create-ilb-ase).  In this reference implementation we focus on Internal ASE. We focus on providing an end to end implementation of an enterprise ASE use case where we leverage best practices across Networking, App Gateway, Firewall, Security (managed service identity) and High Availability.   

# Getting Started
Start with the Deployment folder and follow the Readme file there.  The assumption is that you would have cloned this repo to a local environment where you are able to execute shell scripts.
In the Code folder, there are two sample applications, one a Web Application with an associated API layer.  A second is a function application that executed when messages arrive in the service bus.    


# Build and Run Test
The infrastructure is deployed using the Getting started steps.  The Application layer can be setup to run through a deployment pipeline provided.    

---

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
