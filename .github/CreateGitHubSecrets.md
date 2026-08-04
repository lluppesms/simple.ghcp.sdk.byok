# Set up GitHub Variables and Secrets

This repository uses GitHub Actions with token replacement against [main.bicepparam](infra/Bicep/main.bicepparam). The names below must match exactly.

The deploy workflow also uses environment-scoped credentials (`--env dev` style) for Azure login.

## 1) Required for the workflow to run

Run these commands (customize values):

```bash
gh auth login

# Environment secrets used by azure/login and infra deploy
gh secret set --env dev AZURE_CLIENT_ID -b '<app-registration-client-id>'
gh secret set --env dev AZURE_TENANT_ID -b '<tenant-guid>'
gh secret set --env dev AZURE_SUBSCRIPTION_ID -b '<subscription-guid>'

# Repository/environment variables used by workflow naming and resource-group defaults
gh variable set APP_NAME -b 'ghcp-sdk-byok'
gh variable set RESOURCE_GROUP_LOCATION -b 'centralus'
gh variable set RESOURCE_GROUP_PREFIX -b 'rg-ghcp-sdk-byok'
gh variable set INSTANCE_NUMBER -b '1'

# Token values consumed by infra/Bicep/main.bicepparam
gh variable set ENVCODE -b 'dev'
gh variable set DEPLOYMENT_TYPE -b 'webapp'
gh variable set ADD_ROLE_ASSIGNMENTS -b 'true'
gh variable set CREATE_USER_ASSIGNED_IDENTITY -b 'true'
gh variable set KEYVAULT_OWNER_USERID -b '<entra-object-id>'

# Foundry/model values
gh variable set FOUNDRY_RESOURCE_URL -b 'https://your-foundry-resource.services.ai.azure.com'
gh variable set MODEL_NAME -b 'gpt-5.4-nano'
```

## 2) Optional values (set only if you use them)

These are currently present in [main.bicepparam](infra/Bicep/main.bicepparam). If left blank, behavior depends on the Bicep defaults and module logic.

```bash
# Existing App Service Plan reuse
gh variable set EXISTING_SERVICEPLAN_NAME -b ''
gh variable set EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME -b ''

# Existing Log Analytics reuse
gh variable set EXISTING_LOG_ANALYTICS_WORKSPACE -b ''
gh variable set EXISTING_LOG_ANALYTICS_WORKSPACE_RESOURCE_GROUP_NAME -b ''

```

## Notes

- Use `EXISTING_LOG_ANALYTICS_WORKSPACE` with underscores.
- If you create multiple environments (`dev`, `test`, `prod`), repeat environment secrets with `--env <name>`.

## References

- [Deploying ARM Templates with GitHub Actions](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-github-actions)
- [GitHub Secrets CLI](https://cli.github.com/manual/gh_secret_set)
- [GitHub Variables CLI](https://cli.github.com/manual/gh_variable_set)
