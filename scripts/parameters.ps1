. "$PSScriptRoot\functions.ps1"

# Dependency paths
$envFilePath = ".env.dev"

# Dependency checks
if (-not (Test-Path $envFilePath)) {
    Write-Host ".env.dev file not found." -ForegroundColor Red
    exit
}

Set-EnvVarsFromDotEnvFile -filePath $envFilePath

# Set the Azure tenant ID based on the current account if not set
if (-not ($env:AZURE_TENANT_ID)) {
    $env:AZURE_TENANT_ID = az account show --query tenantId -o tsv
}

# Prompt for input to set/update environment variables
$env:LOCATION = (Prompt-ForInput -prompt "Enter Azure location" -defaultValue $env:LOCATION).ToLower()
$env:PROJECT_NAME = (Prompt-ForInput -prompt "Enter your project name" -defaultValue $env:PROJECT_NAME).ToLower()
$env:CONTAINER_NAME = (Prompt-ForInput -prompt "Enter your container name" -defaultValue $env:CONTAINER_NAME).ToLower()

# Save the environment variables to .env.dev file
$projectVariables = @{
    PROJECT_NAME = $env:PROJECT_NAME
    CONTAINER_NAME = $env:CONTAINER_NAME
    LOCATION = $env:LOCATION
    AZURE_CLIENT_ID = $env:AZURE_CLIENT_ID
    AZURE_TENANT_ID = $env:AZURE_TENANT_ID
}
Save-DotEnvFile -filePath $envFilePath -projectVariables $projectVariables
Write-Host "Configuration saved to $envFilePath"
