# Starter
Starter code for my go-to backend setup.

Bicep file for creating the following Azure resources:

- Log Analytics Workspace
- Application Insights
- User-Assigned Managed Identity for Container
  - ACRPull
  - App Configuration Data Reader
  - Key Vault Secrets User
- Container Registry
- Container App Environment
- Container App "api"
- App Configuration
- Key Vault
  - App Insights Connection String
  - PostgresSQL Coordinator URL
  - PostgresSQL Password
- Cosmos DB PostgreSQL Database

Boilerplate Python code for API:
- FastAPI
- Pydantic
- SQLAlchemy / SQLModel
- Opentelemetry
