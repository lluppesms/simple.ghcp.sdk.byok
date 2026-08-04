# -----------------------------------------------------------------------------
# Creates a new Microsoft Entra web app registration with multiple signin-oidc
# redirect URIs and configures it for Microsoft.Identity.Web
# SignedAssertionFromManagedIdentity.
#
# This adds a "managed-identity-assertion" to the federated credentials of the app registration
#
# The created app registration has no client secret and no certificate. The app
# proves its identity by using a Managed Identity token as a signed assertion.
#
# -ManagedIdentityObjectId is required for the federated credential subject. 
# -ManagedIdentityClientId is only needed when you are using a user-assigned managed identity 
# so Microsoft.Identity.Web knows which managed identity to request tokens from.
# For a system-assigned identity, leave -ManagedIdentityClientId blank.
#
# Example: create one shared app registration for multiple environments
#   .\New-AppRegistrationManagedIdentityAssertion.ps1 `
#       -DisplayName "dadabase-demo-web" `
#       -TenantId "11111111-1111-1111-1111-111111111111" `
#       -ManagedIdentityObjectId "22222222-2222-2222-2222-222222222222","33333333-3333-3333-3333-333333333333" `
#       -RedirectUris "https://myapp-dev.azurewebsites.net/signin-oidc","https://myapp-qa.azurewebsites.net/signin-oidc","https://myapp-prod.azurewebsites.net/signin-oidc"
#
# The AppServiceName and ResourceGroupName parameters are optional. Use them only
# when you want this script to also write settings to one specific App Service.
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Display name for the new app registration")]
    [string]$DisplayName,

    [Parameter(Mandatory = $true, HelpMessage = "Microsoft Entra tenant ID")]
    [string]$TenantId,

    [Parameter(Mandatory = $true, HelpMessage = "Object/principal ID of each managed identity that can assert as this app registration")]
    [string[]]$ManagedIdentityObjectId,

    [Parameter(Mandatory = $false, HelpMessage = "Client ID of the user-assigned managed identity. Leave blank for system-assigned identity.")]
    [string]$ManagedIdentityClientId = "",

    [Parameter(Mandatory = $true, HelpMessage = "One or more web redirect URIs ending in /signin-oidc")]
    [string[]]$RedirectUris,

    [Parameter(Mandatory = $false, HelpMessage = "Federated credential name")]
    [string]$CredentialName = "managed-identity-assertion",

    [Parameter(Mandatory = $false, HelpMessage = "Federated credential subject values. Defaults to ManagedIdentityObjectId values.")]
    [string[]]$FederatedSubject = @(),

    [Parameter(Mandatory = $false, HelpMessage = "Sign-in audience for the app registration")]
    [ValidateSet("AzureADMyOrg", "AzureADMultipleOrgs")]
    [string]$SignInAudience = "AzureADMyOrg",

    [Parameter(Mandatory = $false, HelpMessage = "Azure App Service name to update with required app settings")]
    [string]$AppServiceName = "",

    [Parameter(Mandatory = $false, HelpMessage = "Resource group for AppServiceName")]
    [string]$ResourceGroupName = "",

    [Parameter(Mandatory = $false, HelpMessage = "AzureAD:Instance app setting value")]
    [string]$LoginInstanceEndpoint = "https://login.microsoftonline.com/",

    [Parameter(Mandatory = $false, HelpMessage = "AzureAD:CallbackPath app setting value")]
    [string]$CallbackPath = "/signin-oidc"
)

function Write-Header { param([string]$Message) Write-Host "`n========================================" -ForegroundColor Cyan; Write-Host $Message -ForegroundColor Cyan; Write-Host "========================================" -ForegroundColor Cyan }
function Write-Step { param([string]$Message) Write-Host "  -> $Message" -ForegroundColor Yellow }
function Write-Ok { param([string]$Message) Write-Host "  OK $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "  INFO $Message" -ForegroundColor Gray }
function Write-Fail { param([string]$Message) Write-Host "  ERROR $Message" -ForegroundColor Red }

function Assert-AzCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        Write-Fail "Azure CLI was not found. Install it from https://aka.ms/installazurecli."
        exit 1
    }
}

function Invoke-AzJson {
    param([string[]]$Arguments)
    $json = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($json | Out-String)
    }

    if ([string]::IsNullOrWhiteSpace($json)) {
        return $null
    }

    return $json | ConvertFrom-Json
}

function Add-FederatedCredential {
    param(
        [string]$AppObjectId,
        [string]$Name,
        [string]$Issuer,
        [string]$Subject
    )

    $credentialName = $Name -replace '[^a-zA-Z0-9_-]', '-'
    if ($credentialName.Length -lt 3 -or $credentialName.Length -gt 120) {
        Write-Fail "CredentialName must be 3-120 URL-friendly characters after normalization. Current: '$credentialName'"
        exit 1
    }

    $credentialJson = @{
        name        = $credentialName
        issuer      = $Issuer
        subject     = $Subject
        description = "Allows Microsoft.Identity.Web to use SignedAssertionFromManagedIdentity without a client secret or certificate."
        audiences   = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress

    $tempFile = [System.IO.Path]::GetTempFileName()
    $credentialJson | Out-File -FilePath $tempFile -Encoding utf8

    try {
        Write-Step "Creating federated credential '$credentialName'"
        Write-Info "Issuer : $Issuer"
        Write-Info "Subject: $Subject"
        Write-Info "Audience: api://AzureADTokenExchange"

        & az ad app federated-credential create --id $AppObjectId --parameters $tempFile 1>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Fail "Failed to create federated credential."
            exit 1
        }

        Write-Ok "Federated credential created."
    }
    finally {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
}

function Set-AppServiceSettings {
    param(
        [string]$Name,
        [string]$ResourceGroup,
        [string]$ClientId,
        [string]$Tenant,
        [string]$ManagedIdentityClient,
        [string]$Instance,
        [string]$Callback
    )

    if ([string]::IsNullOrWhiteSpace($Name) -and [string]::IsNullOrWhiteSpace($ResourceGroup)) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($ResourceGroup)) {
        Write-Fail "Provide both -AppServiceName and -ResourceGroupName, or neither."
        exit 1
    }

    $settings = @(
        "AzureAD__Instance=$Instance",
        "AzureAD__TenantId=$Tenant",
        "AzureAD__ClientId=$ClientId",
        "AzureAD__CallbackPath=$Callback",
        "AzureAD__ClientCredentials__0__SourceType=SignedAssertionFromManagedIdentity"
    )

    if (-not [string]::IsNullOrWhiteSpace($ManagedIdentityClient)) {
        $settings += "AzureAD__ClientCredentials__0__ManagedIdentityClientId=$ManagedIdentityClient"
    }

    Write-Step "Applying App Service settings to '$Name'"
    & az webapp config appsettings set --name $Name --resource-group $ResourceGroup --settings @settings 1>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to update App Service settings."
        exit 1
    }

    Write-Ok "App Service settings updated."
}

Write-Header "Create App Registration with Managed Identity Assertion"
Assert-AzCli

if ($RedirectUris.Count -eq 0) {
    Write-Fail "At least one redirect URI is required."
    exit 1
}

$normalizedRedirectUris = @($RedirectUris | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$issuer = "https://login.microsoftonline.com/$TenantId/v2.0"

if ($FederatedSubject.Count -gt 0 -and $FederatedSubject.Count -ne $ManagedIdentityObjectId.Count) {
    Write-Fail "When -FederatedSubject is supplied, provide exactly one subject per -ManagedIdentityObjectId."
    exit 1
}

Write-Step "Creating app registration '$DisplayName'"
$appClientId = & az ad app create --display-name $DisplayName --sign-in-audience $SignInAudience --web-redirect-uris @normalizedRedirectUris --query appId -o tsv 2>&1
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($appClientId)) {
    Write-Fail "Failed to create app registration: $appClientId"
    exit 1
}
$appClientId = $appClientId.Trim()
Write-Ok "Created app registration client ID: $appClientId"

$app = Invoke-AzJson -Arguments @("ad", "app", "show", "--id", $appClientId, "-o", "json")
$appObjectId = $app.id
Write-Info "Application object ID: $appObjectId"
Write-Ok "Redirect URIs configured: $($normalizedRedirectUris -join ', ')"

for ($i = 0; $i -lt $ManagedIdentityObjectId.Count; $i++) {
    $subject = if ($FederatedSubject.Count -gt 0) { $FederatedSubject[$i] } else { $ManagedIdentityObjectId[$i] }
    $name = if ($ManagedIdentityObjectId.Count -eq 1) { $CredentialName } else { "$CredentialName-$($i + 1)" }
    Add-FederatedCredential -AppObjectId $appObjectId -Name $name -Issuer $issuer -Subject $subject
}
Set-AppServiceSettings -Name $AppServiceName -ResourceGroup $ResourceGroupName -ClientId $appClientId -Tenant $TenantId -ManagedIdentityClient $ManagedIdentityClientId -Instance $LoginInstanceEndpoint -Callback $CallbackPath

Write-Host ""
Write-Host "App settings to use:" -ForegroundColor Cyan
Write-Host "  AzureAD__Instance=$LoginInstanceEndpoint"
Write-Host "  AzureAD__TenantId=$TenantId"
Write-Host "  AzureAD__ClientId=$appClientId"
Write-Host "  AzureAD__CallbackPath=$CallbackPath"
Write-Host "  AzureAD__ClientCredentials__0__SourceType=SignedAssertionFromManagedIdentity"
if (-not [string]::IsNullOrWhiteSpace($ManagedIdentityClientId)) {
    Write-Host "  AzureAD__ClientCredentials__0__ManagedIdentityClientId=$ManagedIdentityClientId"
}

Write-Host ""
Write-Host "No client secret or certificate was created. Allow a few minutes for federated credential propagation before testing sign-in." -ForegroundColor Green