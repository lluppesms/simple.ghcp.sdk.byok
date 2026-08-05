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

Before you begin, you will need to set up the Azure Credentials secrets in the GitHub Secrets at the Repository level (or the environment level).  See the **[CreateGitHubSecrets.md](./CreateGitHubSecrets.md)** file for instructions on how to do this.

Once that is set up, you can customize and run the following commands, or you can set these secrets up manually by going to the Settings -> Secrets -> Actions -> Secrets.

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
- [Manage Federated Identity Credential in Entra Id](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp) (MS Learn)
- [Immutable subject claims for GitHub Actions OIDC tokens](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/) (GitHub Changelog Announcement - April 2026)
- [Migrate GitHub Actions federated credentials to immutable subjects - Microsoft Entra Workload ID | Microsoft Learn](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-github-immutable-subjects) (MS Learn)
- [GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
- [GitHub Variables CLI](https://cli.github.com/manual/gh_variable_set)

---

[Home Page](../README.md)
