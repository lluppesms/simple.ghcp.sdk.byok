---
title: Set up GitHub Actions
description: Repository workflow setup notes for deploying resources
author: Repo maintainers
ms.date: 2026-08-06
ms.topic: how-to
estimated_reading_time: 5
---

## Set up GitHub Actions

The GitHub workflows in this project require several secrets set at the repository level or at the environment level.

---

## Workflow Definitions

- **[bicep-build-deploy-webapp.yml](./workflows/bicep-build-deploy-webapp.yml):** Builds an Azure Web App and deploys it to Azure
---

## Azure Credentials

Before you begin, you will need to set up the Azure Credentials secrets in the GitHub Secrets at the Repository level (or the environment level).  These secrets and credentials will allow the GitHub Actions to deploy into Azure.

See [https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions) for more info on how to create the service principal and set up these credentials.

> Note: this service principal must have contributor rights to your subscription (or resource group) to deploy the resources.

You can customize and run the following commands, or you can set these secrets up manually by going to the Settings -> Secrets -> Actions -> Secrets.

You can set these up at the Repository Level...

```bash
gh secret set AZURE_SUBSCRIPTION_ID -b <yourAzureSubscriptionId>
gh secret set AZURE_TENANT_ID -b <GUID-Entra-tenant-where-SP-lives>
gh secret set CICD_CLIENT_ID -b <GUID-application/client-Id>
```

but it's probably better to set up one set of credentials for each Environment:

```bash
gh secret set --env <ENV-NAME> AZURE_SUBSCRIPTION_ID -b <yourAzureSubscriptionId>
gh secret set --env <ENV-NAME> AZURE_TENANT_ID -b <GUID-Entra-tenant-where-SP-lives>
gh secret set --env <ENV-NAME> CICD_CLIENT_ID -b <GUID-application/client-Id>
```

---

## Bicep Configuration Values

There are many values used by the Bicep templates to configure the resource names that are deployed. Make sure the App_Name variable is unique to your deployment. It will be used as the basis for the application name and for all the other Azure resources, some of which must be globally unique.

See the **[CreateGitHubSecrets.md](./CreateGitHubSecrets.md)** file for the full list of commands to create these variables and secrets.

---

## References

- [Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)

---

[Home Page](../README.md)
