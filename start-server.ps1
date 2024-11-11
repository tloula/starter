# ################################# #
# Armedis Containers Docker Compose #
# ################################# #

# Function to read .env.dev file and set environment variables
function Set-EnvVarsFromDotEnvFile {
    param (
        [string]$filePath
    )

    if (Test-Path $filePath) {
        $lines = Get-Content $filePath
        foreach ($line in $lines) {
            if ($line -match '^\s*#') { continue } # Skip comments
            if ($line -match '^\s*$') { continue } # Skip empty lines
            if ($line -match '^\s*([^=]+)\s*=\s*(.*)\s*$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
            }
        }
    }
}

# Start Docker Desktop if necessary
Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Login if necessary
if (-not (az account show)) {
    Write-Host "Logging in to Azure..."
    az login
    Write-Host "Logging in to Azure... Done"
}

# Setup service principal auth since DefaultAzureCredential's token auth methods don't work in Docker containers
Write-Host "Reading environment variables from .env.dev..."
Set-EnvVarsFromDotEnvFile -filePath ".env.dev"
Write-Host "Reading environment variables from .env.dev... Done"

Write-Host "Retrieving developer Entra app client secret..."
if (-not $env:AZURE_CLIENT_SECRET) {
    $env:AZURE_CLIENT_SECRET = az keyvault secret show --name "dev-aad-app-client-secret" --vault-name $env:PROJECT_NAME --query value -o tsv
}
Write-Host "Retrieving developer Entra app client secret... Done"

docker compose up --build
