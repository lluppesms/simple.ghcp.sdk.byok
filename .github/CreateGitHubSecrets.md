# Set up GitHub Variables and Secrets

This repository uses GitHub Actions with token replacement against [main.bicepparam](infra/Bicep/main.bicepparam). The names below must match exactly.

The deploy workflow also uses environment-scoped credentials (`--env dev` style) for Azure login.

## 1) Azure Credentials

Before you begin, you will need to set up the Azure Credentials secrets in the GitHub Secrets at the Repository level (or the environment level).  These secrets and credentials will allow the GitHub Actions to deploy into Azure.

See the reference links below for more info on how to create the service principal and set up the Federated Credentials.

> Note: this service principal must have **Contributor** rights to your subscription (or resource group) to deploy the resources. If you want to assign roles in the Bicep, it will also need the **User Access Administrator** role.  (Alternatively, you can put the service principal in the **Owner** role also, but that doesn't follow least privilege.)

### Update on Federated Credentials
Previously when you set up a federated identity credential in an App Registration to use in a GH Action, you just supplied owner name and repo name and (environment or branch). All repositories created after **July 15, 2026** will have to supply the **IMMUTABLE** values (which are numeric values for the org/user and the repository).

To find those values, run these commands and they will return the numeric **IMMUTABLE** values:
```bash
gh api user --jq .id
gh api repos/<yourOrg>/<yourRepo> --jq .id
```

> NOTE: the first command is for a *USER* (i.e. lluppesms), NOT for an *ORG*…  I'm not sure if there is a different command for that.

---

## 2) Enter the required values for the workflow to run

Run these commands (with customized values) or create these variables in your repository.  This deploy assumes you have a pre-existing AI Foundry already deployed.

```bash
gh auth login

# Environment secrets used to log into Azure for deploy
gh secret set --env dev AZURE_CLIENT_ID -b '<app-registration-client-id>'
gh secret set --env dev AZURE_TENANT_ID -b '<tenant-guid>'
gh secret set --env dev AZURE_SUBSCRIPTION_ID -b '<subscription-guid>'

# Repository (or environment) variables used to name resources
gh variable set APP_NAME -b 'ghcp-sdk-byok'
gh variable set RESOURCE_GROUP_LOCATION -b 'centralus'
gh variable set RESOURCE_GROUP_PREFIX -b 'rg-ghcp-sdk-byok'
gh variable set INSTANCE_NUMBER -b '1'

# Pre-Existing Foundry Name and model name
gh variable set --env dev FOUNDRY_RESOURCE_URL -b 'https://your-foundry-resource.services.ai.azure.com'
gh variable set --env dev FOUNDRY_NAME -b 'your-foundry-resource'
gh variable set --env dev FOUNDRY_RESOURCE_URL -b 'rg-foundry'
gh variable set --env dev MODEL_NAME -b 'gpt-5.6-luna'
gh variable set --env dev ENTRA_TENANT_ID -b '<GUID>'
```

## 3) Optional values (set only if you use them)

If you have an existing App Service Plan that you would like to use, supply these variables:

```bash
# Existing App Service Plan reuse
gh variable set EXISTING_SERVICEPLAN_NAME -b ''
gh variable set EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME -b ''
```

---

## References

- [Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)
- [Manage Federated Identity Credential in Entra Id](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp) (MS Learn)
- [Immutable subject claims for GitHub Actions OIDC tokens](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/) (GitHub Changelog Announcement - April 2026)
- [Migrate GitHub Actions federated credentials to immutable subjects - Microsoft Entra Workload ID | Microsoft Learn](https://learn.microsoft.com/en-us/entra/workload-id/workload-identities-github-immutable-subjects) (MS Learn)
- [GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
- [GitHub Variables CLI](https://cli.github.com/manual/gh_variable_set)

---

[Return to Home Page](../README.md)
