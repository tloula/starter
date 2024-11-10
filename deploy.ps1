# ################################ #
# Armedis Microservices Deployment #
# ################################ #

# Retrieve image version from command line
param(
    [Parameter(Mandatory=$false)]
    [Alias("service-name")]
    [string]$serviceName = "api",
    # Image version, if not specified, the script will get the latest one from ACR and increment it
    [Parameter(Mandatory=$false)]
    [Alias("version")]
    [string]$imageVersion,
    # Build locally or build in ACR
    [Parameter(Mandatory=$false)]
    [Alias("build")]
    [bool]$buildLocally = $true,
    # Whether to deploy the image to Azure Container Apps
    [Parameter(Mandatory=$false)]
    [Alias("deploy")]
    [bool]$deployToContainerApps = $true
)

# Service (image) name and local folder name
$folderName = $serviceName -replace "-", "_"

# Azure Container Registry
$registryName = "armedis"
$imageName = $serviceName
$numberOfImagesToKeep = 2

# Azure Container App
$resourceGroup = "armedis"
$containerAppName = $serviceName

# Start Docker Desktop if necessary
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Login to az cli if necessary
if (-not (az account show)) {
    Write-Host "Logging in to Azure..."
    az login
    Write-Host "Logging in to Azure... Done"
}

# Login to ACR
Write-Host "Logging in to ACR..."
az acr login --name $registryName
Write-Host "Logging in to ACR... Done"

# If image version is not specified, get the latest one from ACR and increment it
# If no image version exists, default to 0.0
if (-not $imageVersion) {
    Write-Host "Retrieving latest image version..."
    $latestVersion = az acr repository show-tags --name $registryName --repository $imageName --orderby time_desc --top 1 --output tsv
    if ($latestVersion) {
        $majorVersion, $minorVersion = $latestVersion -split '\.'
        $minorVersion = [int]$minorVersion + 1
        $imageVersion = "{0}.{1}" -f $majorVersion, $minorVersion
    } else {
        $imageVersion = "0.0"
    }
    Write-Host "New image version: $imageVersion"
    Write-Host "Retrieving latest image version... Done"
}

Write-Host "Using image version: $imageVersion"
Write-Host "Build locally: $buildLocally"
Write-Host "Deploy to Azure Container Apps: $deployToContainerApps"

# Build the Docker image
$ACRTag = "{0}.azurecr.io/{1}:{2}" -f $registryName, $imageName, $imageVersion
$ACRTagLatest = "{0}.azurecr.io/{1}:latest" -f $registryName, $imageName
if ($buildLocally) {
    Write-Host "Building Docker image locally..."
    docker build -f .\$folderName\Dockerfile -t $ACRTag --build-arg SERVICE_VERSION=$imageVersion .
    Write-Host "Building Docker image locally... Done"

    Write-Host "Tagging Docker image as latest..."
    docker tag $ACRTag $ACRTagLatest
    Write-Host "Tagging Docker image as latest... Done"

    Write-Host "Pushing Docker image to ACR..."
    docker push $ACRTag
    Write-Host "Pushing Docker image to ACR... Done" -ForegroundColor Green
} else {
    Write-Host "Building Docker image in ACR..."
    docker build -f .\$folderName\Dockerfile -t $ACRTag --build-arg SERVICE_VERSION=$imageVersion .
    Write-Host "Building Docker image in ACR... Done" -ForegroundColor Green
}

# Deploy the image to Azure Container Apps
if ($deployToContainerApps) {
    Write-Host "Creating new Azure Container App revision..."
    az containerapp update --resource-group $resourceGroup --name $containerAppName --image $ACRTag
    Write-Host "Creating new Azure Container App revision... Done" -ForegroundColor Green
}

# Clean up old images
Write-Host "Cleaning up old images..."
$images = az acr repository show-tags --name $registryName --repository $imageName --orderby time_desc --output tsv
$imagesToDelete = $images | Select-Object -Skip $numberOfImagesToKeep
foreach ($image in $imagesToDelete) {
    Write-Host "Deleting image: $image"
    az acr repository delete --name $registryName --image "${imageName}:${image}" --yes
}
Write-Host "Cleaning up old images... Done"

Write-Host "Deployment of $serviceName $imageVersion complete!" -ForegroundColor Green
