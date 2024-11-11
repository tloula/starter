# Starter

Starter code for my go-to backend setup.

## What's Included

Script for initializing Entra resources:

- Entra App (used to authenticate the container running on a dev machine since DefaultAzureCredential's token auth methods don't work in containers)
- Entra Security Group TM-<Project-Name> for easily controlling RBAC to Azure resources.

Bicep file for creating the following Azure resources:

- Log Analytics Workspace
- Application Insights
- User-Assigned Managed Identity for Container
  - ACRPull
  - App Configuration Data Reader
  - Key Vault Secrets User
- Container Registry
- Container App Environment
- Container App
- App Configuration
- Key Vault
  - App Insights Connection String
  - PostgresSQL Coordinator URL
  - PostgresSQL Password
- Cosmos DB PostgreSQL Database

Boilerplate Python container code for API:

- FastAPI
- Pydantic
- SQLAlchemy / SQLModel
- Opentelemetry

## Getting Started

### Requirements

Ensure the following tools are installed on your machine.

- Docker
- Azure CLI
- Python

### Setup

Run `deploy.ps1` specifying the following when requested.

- `LOCATION`: the Azure region to create resources in (i.e. eastus).
- `PROJECT_NAME`: the name or codename for your project. The Azure resource group and all created resources will use this name. Ensure it is unique to prevent resource creation failures.
- `CONTAINER_NAME`: the name of the container, defaults to `api`.

### Individual Scripts

`deploy.ps1` executes the following scripts sequentially.
You can also run any of them individually, i.e. to just deploy your container without everything else.
All the scripts are idempotent, meaning they can be run repeatedly without any issues.

1. `parameters.ps1`: prompts for user input to set environment variables and save values to `.env.dev`.
2. `deploy-entra.ps1`: creates an Entra app (for dev container authentication), creates an Entra security group for all team members, adds the Entra app to the security group.
3. `deploy-infra.ps1`: deploys the Bicep templates to Azure.
4. `deploy-app.ps1`: deploys the container to Azure Container Apps.
