# -----------------------------------------------------------------------------
# Adds a federated identity credential to an existing Microsoft Entra app
# registration so Microsoft.Identity.Web can use SignedAssertionFromManagedIdentity
# instead of a client secret or certificate.
#
# This adds a "managed-identity-assertion" to the federated credentials of the app registration
#
# The script can also merge web redirect URIs and optionally apply the required
# AzureAD__ClientCredentials app settings to one Azure App Service. The App
# Service update is optional; use it only when you want this script to update a
# specific deployed app after changing the shared app registration.
#
# -ManagedIdentityObjectId is required for the federated credential subject. 
# -ManagedIdentityClientId is only needed when you are using a user-assigned managed identity 
# so Microsoft.Identity.Web knows which managed identity to request tokens from.
# For a system-assigned identity, leave -ManagedIdentityClientId blank.
#
# Example: one shared app registration for multiple environments
#   .\Add-AppRegistrationManagedIdentityAssertion.ps1 `
#       -AppRegistrationClientId "00000000-0000-0000-0000-000000000000" `
#       -TenantId "11111111-1111-1111-1111-111111111111" `
#       -ManagedIdentityObjectId "22222222-2222-2222-2222-222222222222","33333333-3333-3333-3333-333333333333" `
#       -RedirectUris "https://myapp-dev.azurewebsites.net/signin-oidc","https://myapp-qa.azurewebsites.net/signin-oidc"
#
# Example: also update app settings for one App Service after updating the app registration
#   .\Add-AppRegistrationManagedIdentityAssertion.ps1 `
#       -AppRegistrationClientId "00000000-0000-0000-0000-000000000000" `
#       -TenantId "11111111-1111-1111-1111-111111111111" `
#       -ManagedIdentityObjectId "22222222-2222-2222-2222-222222222222" `
#       -RedirectUris "https://myapp-dev.azurewebsites.net/signin-oidc" `
#       -AppServiceName "myapp-dev" `
#       -ResourceGroupName "rg-myapp-dev"
#
# Example: user-assigned managed identity
#   .\Add-AppRegistrationManagedIdentityAssertion.ps1 `
#       -AppRegistrationClientId "00000000-0000-0000-0000-000000000000" `
#       -TenantId "11111111-1111-1111-1111-111111111111" `
#       -ManagedIdentityObjectId "22222222-2222-2222-2222-222222222222" `
#       -ManagedIdentityClientId "33333333-3333-3333-3333-333333333333" `
#       -RedirectUris "https://myapp.azurewebsites.net/signin-oidc"
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Application (client) ID of the existing app registration")]
    [string]$AppRegistrationClientId,

    [Parameter(Mandatory = $true, HelpMessage = "Microsoft Entra tenant ID")]
    [string]$TenantId,

    [Parameter(Mandatory = $true, HelpMessage = "Object/principal ID of each managed identity that can assert as this app registration")]
    [string[]]$ManagedIdentityObjectId,

    [Parameter(Mandatory = $false, HelpMessage = "Client ID of the user-assigned managed identity. Leave blank for system-assigned identity.")]
    [string]$ManagedIdentityClientId = "",

    [Parameter(Mandatory = $false, HelpMessage = "Web redirect URIs to add, such as https://myapp.azurewebsites.net/signin-oidc")]
    [string[]]$RedirectUris = @(),

    [Parameter(Mandatory = $false, HelpMessage = "Replace existing redirect URIs instead of merging")]
    [switch]$ReplaceRedirectUris,

    [Parameter(Mandatory = $false, HelpMessage = "Federated credential name")]
    [string]$CredentialName = "managed-identity-assertion",

    [Parameter(Mandatory = $false, HelpMessage = "Federated credential subject values. Defaults to ManagedIdentityObjectId values.")]
    [string[]]$FederatedSubject = @(),

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

function Get-AppRegistration {
    param([string]$ClientId)
    return Invoke-AzJson -Arguments @("ad", "app", "show", "--id", $ClientId, "-o", "json")
}

function Update-RedirectUris {
    param(
        [string]$AppObjectId,
        [object]$App,
        [string[]]$Uris,
        [bool]$Replace
    )

    if ($Uris.Count -eq 0) {
        return
    }

    $existingUris = @()
    if ($App.web -and $App.web.redirectUris) {
        $existingUris = @($App.web.redirectUris)
    }

    $targetUris = if ($Replace) {
        @($Uris)
    }
    else {
        @($existingUris + $Uris | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    }

    Write-Step "Updating web redirect URIs on app registration"
    & az ad app update --id $AppObjectId --web-redirect-uris @targetUris 1>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to update redirect URIs."
        exit 1
    }

    Write-Ok "Redirect URIs configured: $($targetUris -join ', ')"
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

    $existingCredentials = Invoke-AzJson -Arguments @("ad", "app", "federated-credential", "list", "--id", $AppObjectId, "-o", "json")
    $existing = @($existingCredentials | Where-Object { $_.name -eq $credentialName })
    if ($existing.Count -gt 0) {
        Write-Info "Federated credential '$credentialName' already exists. Skipping create."
        return
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

Write-Header "Configure Managed Identity Assertion for Existing App Registration"
Assert-AzCli

$app = Get-AppRegistration -ClientId $AppRegistrationClientId
$appObjectId = $app.id
$issuer = "https://login.microsoftonline.com/$TenantId/v2.0"

if ($FederatedSubject.Count -gt 0 -and $FederatedSubject.Count -ne $ManagedIdentityObjectId.Count) {
    Write-Fail "When -FederatedSubject is supplied, provide exactly one subject per -ManagedIdentityObjectId."
    exit 1
}

Write-Ok "Found app registration '$($app.displayName)'"
Write-Info "Application client ID: $AppRegistrationClientId"
Write-Info "Application object ID: $appObjectId"

Update-RedirectUris -AppObjectId $appObjectId -App $app -Uris $RedirectUris -Replace $ReplaceRedirectUris.IsPresent
for ($i = 0; $i -lt $ManagedIdentityObjectId.Count; $i++) {
    $subject = if ($FederatedSubject.Count -gt 0) { $FederatedSubject[$i] } else { $ManagedIdentityObjectId[$i] }
    $name = if ($ManagedIdentityObjectId.Count -eq 1) { $CredentialName } else { "$CredentialName-$($i + 1)" }
    Add-FederatedCredential -AppObjectId $appObjectId -Name $name -Issuer $issuer -Subject $subject
}
Set-AppServiceSettings -Name $AppServiceName -ResourceGroup $ResourceGroupName -ClientId $AppRegistrationClientId -Tenant $TenantId -ManagedIdentityClient $ManagedIdentityClientId -Instance $LoginInstanceEndpoint -Callback $CallbackPath

Write-Host ""
Write-Host "App settings to use:" -ForegroundColor Cyan
Write-Host "  AzureAD__Instance=$LoginInstanceEndpoint"
Write-Host "  AzureAD__TenantId=$TenantId"
Write-Host "  AzureAD__ClientId=$AppRegistrationClientId"
Write-Host "  AzureAD__CallbackPath=$CallbackPath"
Write-Host "  AzureAD__ClientCredentials__0__SourceType=SignedAssertionFromManagedIdentity"
if (-not [string]::IsNullOrWhiteSpace($ManagedIdentityClientId)) {
    Write-Host "  AzureAD__ClientCredentials__0__ManagedIdentityClientId=$ManagedIdentityClientId"
}

Write-Host ""
Write-Host "No client secret or certificate is required. Allow a few minutes for federated credential propagation before testing sign-in." -ForegroundColor Green