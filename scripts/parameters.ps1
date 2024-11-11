# Function to read .env.dev file and return a hashtable of key-value pairs
function Read-DotEnvFile {
    param (
        [string]$filePath
    )

    $projectVariables = @{}
    if (Test-Path $filePath) {
        $lines = Get-Content $filePath
        foreach ($line in $lines) {
            if ($line -match '^\s*#') { continue } # Skip comments
            if ($line -match '^\s*$') { continue } # Skip empty lines
            if ($line -match '^\s*([^=]+)\s*=\s*(.*)\s*$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $projectVariables[$key] = $value
            }
        }
    }
    return $projectVariables
}

# Function to save environment variables to .env.dev file
function Save-DotEnvFile {
    param (
        [string]$filePath,
        [hashtable]$projectVariables
    )

    # Read the existing file content
    $existingLines = @()
    if (Test-Path $filePath) {
        $existingLines = Get-Content $filePath
    }

    # Create a hashtable to store the updated variables
    $updatedVariables = @{}

    # Process each line and update the variables
    for ($i = 0; $i -lt $existingLines.Count; $i++) {
        $line = $existingLines[$i]
        if ($line -match '^\s*#') { continue } # Skip comments
        if ($line -match '^\s*$') { continue } # Skip empty lines
        if ($line -match '^\s*([^=]+)\s*=\s*(.*)\s*$') {
            $key = $matches[1].Trim()
            if ($projectVariables.ContainsKey($key)) {
                $existingLines[$i] = "$key=$($projectVariables[$key])"
                $updatedVariables[$key] = $true
            }
        }
    }

    # Add any new variables that were not already in the file
    foreach ($key in $projectVariables.Keys) {
        if (-not $updatedVariables.ContainsKey($key)) {
            $existingLines += "$key=$($projectVariables[$key])"
        }
    }

    # Write the updated content back to the file
    Set-Content -Path $filePath -Value $existingLines
}

# Function to prompt for input with a default value
function Prompt-ForInput {
    param (
        [string]$prompt,
        [string]$defaultValue
    )

    $input = Read-Host "$prompt [$defaultValue]"
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $defaultValue
    }
    return $input
}

# Dependency paths
$envFilePath = ".env.dev"

# Dependency checks
if (-not (Test-Path $envFilePath)) {
    Write-Host ".env.dev file not found." -ForegroundColor Red
    exit
}

$projectVariables = Read-DotEnvFile -filePath $envFilePath

# Prompt for input to set/update environment variables
$env:LOCATION = (Prompt-ForInput -prompt "Enter Azure location (i.e. eastus)" -defaultValue $projectVariables['LOCATION']).ToLower()
$env:PROJECT_NAME = (Prompt-ForInput -prompt "Enter your project name" -defaultValue $projectVariables['PROJECT_NAME']).ToLower()
$env:CONTAINER_NAME = (Prompt-ForInput -prompt "Enter your container name" -defaultValue $projectVariables['CONTAINER_NAME']).ToLower()

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
