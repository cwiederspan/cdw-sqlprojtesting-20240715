@description('The base name of the resources to create.')
param baseName string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The name of the database to create within the SQL server.')
param databaseName string

@description('The administrator username of the SQL logical server.')
param sqlUsername string = 'sqlsa'

@description('The administrator password of the SQL logical server.')
@secure()
param sqlPassword string

resource muid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${baseName}-muid'
  location: location
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: '${baseName}-law'
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${baseName}-apm'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: '${baseName}-sql'
  location: location
  properties: {
    administratorLogin: sqlUsername
    administratorLoginPassword: sqlPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: 'Application'
      azureADOnlyAuthentication: false
      login: muid.name
      sid: muid.properties.clientId
      tenantId: muid.properties.tenantId
    }
  }
  resource AllowAllWindowsAzureIps 'firewallRules@2023-05-01-preview' = {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      endIpAddress: '0.0.0.0'
      startIpAddress: '0.0.0.0'
    }
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  parent: sqlServer
  name: databaseName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

resource environment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${baseName}-env'
  location: location
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-03-01' ={
  name: '${baseName}-aca'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${muid.id}': {}
    }
  }
  properties:{
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
    }
    template: {
      containers: [
        {
          image: 'cwiederspan/adventureworksdab:latest'
          name: 'dab-adventureworks'
          env: [
            {
              name: 'DATABASE_CONNECTION_STRING'
              value: 'Server=${sqlServer.properties.fullyQualifiedDomainName};Database=${sqlDB.name};Encrypt=true;Authentication=Active Directory Default;'
            }
          ]
        }
      ]
    }
  }
}
