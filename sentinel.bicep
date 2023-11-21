//https://learn.microsoft.com/en-us/azure/templates/  Bicep resource references

@description('The Azure region into which the resources should be deployed.')
param location string = 'norwayeast'

@description('Name of the project or solution')
@minLength(3)
@maxLength(37)
param projectName string

@description('Generated the workspace name.')
var workspaceName = 'law-${projectName}'

//Log Analytics creation
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}
// Resource definition for Sentinel
resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspaceName})'
  location: location // Location from the parameter
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id // Reference to Log Analytics Workspace ID
  }
  plan: {
    name: 'SecurityInsights(${workspaceName})'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}

//https://learn.microsoft.com/en-us/azure/templates/microsoft.securityinsights/dataconnectors?pivots=deployment-language-bicep
//Need to have Entra ID P2 for data connector to work. 
resource AzureADSolution 'Microsoft.SecurityInsights/contentPackages@2023-09-01-preview' = {
  name: 'AzureActiveDirectoryPackage'
  scope: logAnalyticsWorkspace
  dependsOn: [
    sentinel
  ]
  properties: {
    version: '3.0.6'
    providers: ['Microsoft']
    contentId: 'azuresentinel.azure-sentinel-solution-azureactivedirectory'
    contentProductId: 'azuresentinel.azure-sentinel-solution-azureactivedirectory'
    //Content id location: https://github.com/Azure/Azure-Sentinel/blob/master/Solutions/Microsoft%20Entra%20ID/Package/mainTemplate.json
  }
}
resource azureADDataConnector 'Microsoft.SecurityInsights/dataConnectors@2023-09-01-preview' = {
  name: 'AzureActiveDirectoryDataConnector'
  kind: 'AzureActiveDirectory'
  scope: logAnalyticsWorkspace
  dependsOn: [
    AzureADSolution
  ]
  properties: {
    dataTypes: {
      alerts: {
        state: 'Enabled'
      }
    }
    tenantId: 'b8a2c36b-eba9-4dfa-b151-15c03efaa2be'
  }
}

