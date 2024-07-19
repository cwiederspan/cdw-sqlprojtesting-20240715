# SQL Project Testing

A testing project for working with SQL projects and deployment pipelines.

## Project Setup

```bash

# Install Azure CLI

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash


# Setup Environment Variables

source .env


# Login to Azure

az login -t $TENANT_ID


# Create a Resource Group

az group create --name $BASE_NAME --location $LOCATION


# Create the SQL Server and Database

az deployment group create -g $BASE_NAME \
--template-file ./infra/main.bicep \
--parameters \
baseName=$BASE_NAME \
location=$LOCATION \
databaseName=AdventureWorksLT


# Clean up and delete the Resource Group

az group delete --name $BASE_NAME --yes


# Other miscellaneous

docker build -t cwiederspan/adventureworksdab:latest -f ./dab/Dockerfile ./dab

docker push 

```