# Set up GitHub Variables and Secrets

This repository uses GitHub Actions with token replacement against [main.bicepparam](infra/Bicep/main.bicepparam). The names below must match exactly.

The deploy workflow also uses environment-scoped credentials (`--env dev` style) for Azure login.

## 1) Required for the workflow to run

Run these commands (customize values):

```bash
gh auth login

# Environment secrets used to log into Azure for deploy
gh secret set --env dev AZURE_CLIENT_ID -b '<app-registration-client-id>'
gh secret set --env dev AZURE_TENANT_ID -b '<tenant-guid>'
gh secret set --env dev AZURE_SUBSCRIPTION_ID -b '<subscription-guid>'

# Repository or environment variables used by to name resources
gh variable set APP_NAME -b 'ghcp-sdk-byok'
gh variable set RESOURCE_GROUP_LOCATION -b 'centralus'
gh variable set RESOURCE_GROUP_PREFIX -b 'rg-ghcp-sdk-byok'
gh variable set INSTANCE_NUMBER -b '1'

# Foundry Name and model name
gh variable set FOUNDRY_RESOURCE_URL -b 'https://your-foundry-resource.services.ai.azure.com'
gh variable set MODEL_NAME -b 'gpt-5.6-luna'
```

## 2) Optional values (set only if you use them)

If you have an existing App Service Plan or Log Analytics Workspace that you would like to use, supply these variables:

```bash
# Existing App Service Plan reuse
gh variable set EXISTING_SERVICEPLAN_NAME -b ''
gh variable set EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME -b ''

# Existing Log Analytics reuse
gh variable set EXISTING_LOG_ANALYTICS_WORKSPACE -b ''
gh variable set EXISTING_LOG_ANALYTICS_WORKSPACE_RESOURCE_GROUP_NAME -b ''

```

## References

- [Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)
- [GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
- [GitHub Variables CLI](https://cli.github.com/manual/gh_variable_set)
