@secure()
param paramSqlUsername string

@secure()
param paramSqlPassword string

param paramlocation string = resourceGroup().location
param resRouteTable string
param paramAppSubnetAddressPrefix string
param paramSqlSubnetAddressPrefix string
param paramStSubnetAddressPrefix string
param paramVnetAddressPrefix string
param paramVnetName string
param paramAppSubnetName string
param paramSqlSubnetName string
param paramStSubnetName string
param paramAspNsgName string
param paramSqlNsgName string
param paramStNsgName string
param paramAspName string
param paramAppServiceName string
param paramSqlServerName string
param paramSqlServerDatabaseName string
param privateAspDnsZoneName string
param SqlDbPrivateDnsZoneName string
param paramSqlDbPrivateEndpointName string
param paramAspPrivateEndpointName string
param paramStorageAccount string
param paramStPrivateEndpointName string
param paramStPrivateDnsZoneName string
param paramAppInsightName string
param appName string
param paramStPrivateDnsZoneId string
param paramAspPrivateDnsZoneId string
param paramKeyVaultPrivateDnsZoneName string
param paramSqlPrivateDnsZoneId string
param paramDept string

// <-- SPOKE VIRTUAL NETWORK --> //

resource resSpokeVnet 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: paramVnetName
  location: paramlocation
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        paramVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: paramAppSubnetName
        properties: {
          addressPrefix: paramAppSubnetAddressPrefix
          networkSecurityGroup: {
            id: aspNetworkSecurityGroup.id
          }
          routeTable: {
            id: resRouteTable
          }
        }
      }
      {
        name: paramSqlSubnetName
        properties: {
          addressPrefix: paramSqlSubnetAddressPrefix
          networkSecurityGroup: {
            id: sqlNetworkSecurityGroup.id
          }
          routeTable: {
            id: resRouteTable
          }
        }
      }
      {
        name: paramStSubnetName
        properties: {
          addressPrefix: paramStSubnetAddressPrefix
          networkSecurityGroup: {
            id: stNetworkSecurityGroup.id
          }
          routeTable: {
            id: resRouteTable
          }
        }
      }
    ]
  }
}

// PRIVATE DNS ZONE LINKS

resource resStDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${paramStPrivateDnsZoneName}/${resSpokeVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resSpokeVnet.id
    }
  }
}

resource resSqlDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${SqlDbPrivateDnsZoneName}/${resSpokeVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resSpokeVnet.id
    }
  }
}

resource resAspDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateAspDnsZoneName}/${resSpokeVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resSpokeVnet.id
    }
  }
}

resource resKvDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${paramKeyVaultPrivateDnsZoneName}/${resSpokeVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resSpokeVnet.id
    }
  }
}

// <-- APP SERVICE RESOURCES --> //

resource resAppSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: paramAppSubnetName
  parent: resSpokeVnet
}

resource aspNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: paramAspNsgName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  properties: {
    securityRules: [
      {
        name: 'nsgRule'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource resAppServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: paramAspName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  sku: {
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource resSpokeAppService 'Microsoft.Web/sites@2022-09-01' = {
  name: paramAppServiceName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  dependsOn: [
    resLogAnalytics
  ]
  properties: {
    serverFarmId: resAppServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|7.0'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
  }
}

resource resProdSrcControls 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = {
  parent: resSpokeAppService
  name: 'web'
  properties: {
    repoUrl: 'https://github.com/Azure-Samples/dotnetcore-docs-hello-world'
    branch: 'master'
    isManualIntegration: true
      }
    }

  resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: paramAppInsightName
  location: paramlocation
  kind: 'web'
  tags: {
    displayName: 'AppInsight'
    ProjectName: appName
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: resLogAnalytics.id
  }
}

resource resAspPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: paramAspPrivateEndpointName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
      location: paramlocation
      properties: {
        subnet: {
          id: resAppSubnet.id
        }
        privateLinkServiceConnections: [
          {
            name: paramAspPrivateEndpointName
            properties: {
              privateLinkServiceId: resSpokeAppService.id
              groupIds: [
                'sites'
              ]
            }
          }
        ]
      }
    }
    
resource pvtAspEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: resAspPrivateEndpoint
    name: 'myaspdnsgroupname'
      properties: {
        privateDnsZoneConfigs: [
          {
            name: 'aspconfig'
            properties: {
              privateDnsZoneId: paramAspPrivateDnsZoneId
            }
          }
        ]
      }
    }

// <-- SQL RESOURCES --> //

resource sqlServer 'Microsoft.Sql/servers@2023-02-01-preview' ={
  name: paramSqlServerName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  properties: {
    administratorLogin: paramSqlUsername
    administratorLoginPassword: paramSqlPassword
  }
}
    
resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2023-02-01-preview' = {
  parent: sqlServer
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  name: paramSqlServerDatabaseName
  location: paramlocation
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
}

resource resSqlDbPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: paramSqlDbPrivateEndpointName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  properties: {
    subnet: {
      id: resSqlSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: paramSqlDbPrivateEndpointName
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource resSqlDbEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: resSqlDbPrivateEndpoint
  name: 'mysqldnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sqlconfig'
        properties: {
          privateDnsZoneId:paramSqlPrivateDnsZoneId
        }
      }
    ]
  }
}

resource resSqlSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: paramSqlSubnetName
  parent: resSpokeVnet
}

resource sqlNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: paramSqlNsgName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  properties: {
    securityRules: [
      {
        name: 'nsgRule'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

// <-- STORAGE ACCOUNT RESOURCES --> //

resource resStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: paramStorageAccount
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource resStPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: paramStPrivateEndpointName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  properties: {
    subnet: {
      id: resStSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: paramStPrivateEndpointName
        properties: {
          privateLinkServiceId: resStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource resStEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: resStPrivateEndpoint
  name: 'mystdnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'stconfig'
        properties: {
          privateDnsZoneId: paramStPrivateDnsZoneId
        }
      }
    ]
  }
}

resource resStSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: paramStSubnetName
  parent: resSpokeVnet
}

resource stNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: paramStNsgName
  tags: {
    Owner: 'Sandy'
    Dept: paramDept
  }
  location: paramlocation
  properties: {
    securityRules: [
      {
        name: 'nsgRule'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

// <-- OUTPUTS --> //

resource resLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: 'log-core-${paramlocation}-001-123'
}

output outVnetId string = resSpokeVnet.id
output outVnetName string = resSpokeVnet.name

output outSqlServerId string = sqlServer.id

output outStorageAccountEndpoint string = resStorageAccount.properties.primaryEndpoints.blob

output outProdFqdn string = resSpokeAppService.properties.defaultHostName
