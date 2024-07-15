@description('The base name of the resources to create.')
param baseName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the database to create within the SQL server.')
param databaseName string

@description('The administrator username of the SQL logical server.')
param adminUsername string = 'sqlsa'

@description('The administrator password of the SQL logical server.')
@secure()
param adminPassword string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: '${baseName}-sql'
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
  }

  resource AllowAllWindowsAzureIps 'firewallRules@2023-05-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      endIpAddress: '0.0.0.0'
      startIpAddress: '0.0.0.0'
    }
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}
