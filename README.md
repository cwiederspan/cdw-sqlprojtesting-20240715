# SQL Project Testing

A testing project for working with SQL projects and deployment pipelines.

## Project Setup

```bash

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install the Data API Builder CLI
dotnet new tool-manifest
dotnet tool install -g Microsoft.DataApiBuilder

# Setup Environment Variables
source .env

# Login to Azure
az login -t $TENANT_ID

# Create a Resource Group
az group create --name $BASE_NAME --location $LOCATION

# Create a Service Principal
az ad sp create-for-rbac --name $BASE_NAME-sp --sdk-auth --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$BASE_NAME

# Create the SQL Server and Database
az deployment group create -g $BASE_NAME \
--template-file ./infra/main.bicep \
--parameters \
baseName=$BASE_NAME \
location=$LOCATION \
databaseName=AdventureWorksLT \
sqlUsername=$SQL_USER \
sqlPassword=$SQL_PASSWORD

# Setup the DAB configuration file
dab init --database-type "mssql" --connection-string "@env('DATABASE_CONNECTION_STRING')"
dab add Product --source "SalesLT.Product" --permissions "anonymous:read"
dab add Customer --source "SalesLT.Customer" --permissions "anonymous:read"

# Other miscellaneous
docker build -t cwiederspan/adventureworksdab:latest -f ./dab/Dockerfile ./dab
docker push 

# Clean up and delete the Resource Group
az group delete --name $BASE_NAME --yes

```