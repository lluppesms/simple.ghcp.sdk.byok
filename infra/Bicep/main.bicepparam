// ----------------------------------------------------------------------------------------------------
// Shared Pipeline Parameter File (Azure DevOps + GitHub Actions)
// ----------------------------------------------------------------------------------------------------
using './main.bicep'

param appName = '#{APP_NAME}#'
param environmentCode = '#{ENVCODE}#'
param location = '#{RESOURCE_GROUP_LOCATION}#'
param instanceNumber = '#{INSTANCE_NUMBER}#'
param deploymentType = '#{DEPLOYMENT_TYPE}#'
param appDataSource = 'SQL'
param addRoleAssignments = trim(toLower('#{ADD_ROLE_ASSIGNMENTS}#')) == 'true'
param createUserAssignedIdentity = trim(toLower('#{CREATE_USER_ASSIGNED_IDENTITY}#')) == 'true'

param adminUserList = '#{ADMIN_USER_LIST}#'
param adInstance = '#{LOGIN_INSTANCEENDPOINT}#'
param adDomain = '#{LOGIN_DOMAIN}#'
param adTenantId = '#{LOGIN_TENANTID}#'
param adClientId = '#{LOGIN_CLIENTID}#'
param webApiKey = '#{WEB_API_KEY}#'
param servicePlanName = '#{EXISTING_SERVICEPLAN_NAME}#'
param servicePlanResourceGroupName = '#{EXISTING_SERVICEPLAN_RESOURCE_GROUP_NAME}#'
param webAppKind = 'linux' // 'linux' or 'windows'

param sqlAdminLoginUserId = '#{SQLADMIN_LOGIN_USERID}#'
param sqlAdminLoginUserSid = '#{SQLADMIN_LOGIN_USERSID}#'
param sqlAdminLoginTenantId = '#{SQLADMIN_LOGIN_TENANTID}#'

param sqlDatabaseName = '#{SQL_DATABASE_NAME}#'
param existingSqlServerName = '#{EXISTING_SQLSERVER_NAME}#'
param existingSqlDatabaseName = '#{EXISTING_SQLDATABASE_NAME}#'
param existingSqlServerResourceGroupName = '#{EXISTING_SQLSERVER_RESOURCE_GROUP_NAME}#'
param existingLogAnalyticsWorkspaceName = '#{EXISTING_LOG_ANALYTICS_WORKSPACE}#'
param existingLogAnalyticsWorkspaceResourceGroupName = '#{EXISTING_LOG_ANALYTICS_WORKSPACE_RESOURCE_GROUP_NAME}#'
// param existingSignalRName = '#{EXISTING_SIGNALR}#'

param adminUserId = '#{KEYVAULT_OWNER_USERID}#'

param containerImage = '#{CONTAINER_IMAGE}#'
param containerRegistrySku = 'Basic'
param pipelineServicePrincipalObjectId = '#{PIPELINE_SERVICE_PRINCIPAL_OBJECT_ID}#'

param azureOpenAIChatEndpoint = '#{OPENAI_CHAT_ENDPOINT}#'
param azureOpenAIChatDeploymentName = '#{OPENAI_CHAT_DEPLOYMENTNAME}#'
param azureOpenAIChatApiKey = '#{OPENAI_CHAT_APIKEY}#'
param azureOpenAIChatMaxTokens = '#{OPENAI_CHAT_MAXTOKENS}#'
param azureOpenAIChatTemperature = '#{OPENAI_CHAT_TEMPERATURE}#'
param azureOpenAIChatTopP = '#{OPENAI_CHAT_TOPP}#'
param azureOpenAIImageEndpoint = '#{OPENAI_IMAGE_ENDPOINT}#'
param azureOpenAIImageDeploymentName = '#{OPENAI_IMAGE_DEPLOYMENTNAME}#'
param azureOpenAIImageApiKey = '#{OPENAI_IMAGE_APIKEY}#'
