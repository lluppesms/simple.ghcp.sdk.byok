# -----------------------------------------------------------------------------
# Example Usage:
# .\infra\bicep\Scripts\Add-FederatedCredentials.ps1 -AppRegistrationName "YOUR-APP-REG-NAME" -GitHubOrg "YOUR-GH-ORG" -GitHubRepo "logicapp.processing.agent" -EnvironmentName "dev"
# .\Add-FederatedCredentials.ps1 -AppRegistrationName "lyleluppes_gh_actions_2" -GitHubOrg "lluppesms" -GitHubRepo "logicapp.processing.agent" -EnvironmentName "dev"
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "The display name of the Azure AD app registration")]
    [string]$AppRegistrationName,

    [Parameter(Mandatory = $true, HelpMessage = "The GitHub organization or username")]
    [string]$GitHubOrg,

    [Parameter(Mandatory = $true, HelpMessage = "The GitHub repository name")]
    [string]$GitHubRepo,

    [Parameter(Mandatory = $true, HelpMessage = "The GitHub environment names")]
    [string]$EnvironmentName
)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  ℹ $Message" -ForegroundColor Gray
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Add-FederatedCredential {
    param([string]$AppObjectId,[string]$Name, [string]$Subject, [string]$Description)

    $credentialName = $Name -replace '[^a-zA-Z0-9-_]', '-'
    
    Write-Step "Adding federated credential: $credentialName"
    Write-Info "Subject: $Subject"

    # Check if credential already exists
    $existingCredentials = az ad app federated-credential list --id $AppObjectId --query "[?name=='$credentialName']" -o json 2>$null | ConvertFrom-Json
    
    if ($existingCredentials -and $existingCredentials.Count -gt 0) {
        Write-Info "Federated credential '$credentialName' already exists. Skipping..."
        return $true
    }

    # Create the federated credential
    $credentialJson = @{
        name        = $credentialName
        issuer      = "https://token.actions.githubusercontent.com"
        subject     = $Subject
        description = $Description
        audiences   = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Compress

    # Write to temp file to avoid escaping issues
    $tempFile = [System.IO.Path]::GetTempFileName()
    $credentialJson | Out-File -FilePath $tempFile -Encoding utf8

    try {
        $result = az ad app federated-credential create --id $AppObjectId --parameters $tempFile 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Successfully added federated credential: $credentialName"
            return $true
        }
        else {
            Write-ErrorMessage "Failed to add federated credential: $result"
            return $false
        }
    }
    finally {
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------
Write-Header "Adding Federated Credentials for GitHub Actions"

# Check if Azure CLI is installed and logged in
Write-Step "Checking Azure CLI authentication..."
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-ErrorMessage "Not logged in to Azure CLI. Please run 'az login' first."
    exit 1
}
Write-Success "Logged in as: $($account.user.name)"
Write-Info "Subscription: $($account.name)"

# Get the app registration
Write-Step "Looking up app registration: $AppRegistrationName"
$app = az ad app list --display-name $AppRegistrationName --query "[0]" -o json 2>$null | ConvertFrom-Json

if (-not $app) {
    Write-ErrorMessage "App registration '$AppRegistrationName' not found."
    exit 1
}

$appId = $app.appId
$appObjectId = $app.id
Write-Success "Found app registration"
Write-Info "App ID (Client ID): $appId"
Write-Info "Object ID: $appObjectId"

Write-Host ""
Write-Host "GitHub Repository: $GitHubOrg/$GitHubRepo" -ForegroundColor Magenta
Write-Host ""

$successCount = 0
$failCount = 0

# Add federated credentials for environment
$subject = "repo:${GitHubOrg}/${GitHubRepo}:environment:${EnvironmentName}"
$description = "GitHub Actions deployment to $EnvironmentName environment"
$name = "gh==${GitHubOrg}==$GitHubRepo==$EnvironmentName"

if (Add-FederatedCredential -AppObjectId $appObjectId -Name $name -Subject $subject -Description $description) {
    $successCount++
}
else {
    $failCount++
}

# Summary
Write-Header "Summary"
Write-Host "  Total credentials processed: $($successCount + $failCount)" -ForegroundColor White
Write-Host "  Successful: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "  Failed: $failCount" -ForegroundColor Red
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Ensure the following secrets are set in your GitHub repository:" -ForegroundColor White
Write-Host "     - AZURE_CLIENT_ID: $appId" -ForegroundColor Gray
Write-Host "     - AZURE_TENANT_ID: $($account.tenantId)" -ForegroundColor Gray
Write-Host "     - AZURE_SUBSCRIPTION_ID: $($account.id)" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. In your GitHub Actions workflow, use:" -ForegroundColor White
Write-Host @"
     - name: Azure Login
       uses: azure/login@v2
       with:
         client-id: `${{ secrets.AZURE_CLIENT_ID }}
         tenant-id: `${{ secrets.AZURE_TENANT_ID }}
         subscription-id: `${{ secrets.AZURE_SUBSCRIPTION_ID }}
"@ -ForegroundColor Gray
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "✓ All federated credentials configured successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "⚠ Some credentials failed to configure. Please review the errors above." -ForegroundColor Yellow
    exit 1
}
