param paramLogAnalyticsName string = 'log-core-${paramlocation}-001-123'
param paramAppInsightsName string = 'appinsights-001'

param keyVaultObjectId string
param keyVaultName string
param randNumb string
param paramlocation string

var varSqlEndpoint = 'privatelink${environment().suffixes.sqlServerHostname}'
var varKeyVaultEndpoint = 'privatelink${environment().suffixes.keyvaultDns}'
var varStEndpoint = 'privatelink.blob.${environment().suffixes.storage}'

// VIRTUAL NETWORKS //

module modHubVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'HubVirtualNetwork'
  params: {
    name: 'Hub-${paramlocation}-001'
    // Required parameters
    addressPrefixes: [
      '10.10.0.0/16'
    ]
    // Non-required parameters
    location: paramlocation
    subnets: [
      {
        addressPrefix: '10.10.1.0/24'
        name: 'GatewaySubnet'
      }
      {
        addressPrefix: '10.10.2.0/24'
        name: 'appGWSubnet'
      }
      {
        addressPrefix: '10.10.3.0/24'
        name: 'azureFirewallSubnet'
      }
      {
        addressPrefix: '10.10.4.0/24'
        name: 'azureBastionSubnet'
      }
    ]
  }
}

module modCoreVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'CoreVirtualNetwork'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.20.0.0/16'
    ]
    name: 'core-${paramlocation}-001'
    // Non-required parameters
    location: paramlocation
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: true
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'Core-to-Hub-Peering'
        remoteVirtualNetworkId: modHubVirtualNetwork.outputs.resourceId
        useRemoteGateways: false
      }
    ]
    subnets: [
      {
        addressPrefix: '10.20.1.0/24'
        name: 'vmSubnet'
        networkSecurityGroup: {
          id: modNetworkSecurityGroup
        }
        routeTable: {
          id: modRouteTable.outputs.resourceId
        }
      }
      {
        addressPrefix: '10.20.2.0/24'
        name: 'kvSubnet'
        networkSecurityGroup: {
          id: modNetworkSecurityGroup
        }
        routeTable: {
          id: modRouteTable.outputs.resourceId
        }
      }
    ]
  }
}

module modDevSpokeVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'DevVirtualNetwork'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.30.0.0/16'
    ]
    name: 'dev-${paramlocation}-001'
    // Non-required parameters
    location: paramlocation
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: true
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'Dev-to-Hub-Peering'
        remoteVirtualNetworkId: modHubVirtualNetwork.outputs.resourceId
        useRemoteGateways: false
      }
    ]
    subnets: [
      {
        name: 'AppSubnet'
        properties: {
          addressPrefix: '10.30.1.0/24'
          networkSecurityGroup: {
            id: modNetworkSecurityGroup
          }
          routeTable: {
            id: modRouteTable.outputs.resourceId
          }
        }
      }
      {
        name: 'SqlSubnet'
        properties: {
          addressPrefix: '10.30.2.0/24'
          networkSecurityGroup: {
            id: modNetworkSecurityGroup
          }
          routeTable: {
            id: modRouteTable.outputs.resourceId
          }
        }
      }
      {
        name: 'StSubnet'
        properties: {
          addressPrefix: '10.30.3.0/24'
          networkSecurityGroup: {
            id: modNetworkSecurityGroup
          }
          routeTable: {
            id: modRouteTable.outputs.resourceId
          }
        }
      }
    ]
  }
}

module modProdSpokeVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'ProdVirtualNetwork'
  params: {
    // Required parameters
    addressPrefixes: [
      '10.31.0.0/16'
    ]
    name: 'prod-${paramlocation}-001'
    // Non-required parameters
    location: paramlocation
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: true
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'Prod-to-Hub-Peering'
        remoteVirtualNetworkId: modHubVirtualNetwork.outputs.resourceId
        useRemoteGateways: false
      }
    ]
    subnets: [
      {
        name: 'AppSubnet'
        properties: {
          addressPrefix: '10.31.1.0/24'
          networkSecurityGroup: {
            id: modNetworkSecurityGroup
          }
          routeTable: {
            id: modRouteTable.outputs.resourceId
          }
        }
      }
      {
        name: 'SqlSubnet'
        properties: {
          addressPrefix: '10.31.2.0/24'
          networkSecurityGroup: {
            id: modNetworkSecurityGroup
          }
          routeTable: {
            id: modRouteTable.outputs.resourceId
          }
        }
      }
      {
        name: 'StSubnet'
        properties: {
          addressPrefix: '10.31.3.0/24'
          networkSecurityGroup: {
            id: modNetworkSecurityGroup
          }
          routeTable: {
            id: modRouteTable.outputs.resourceId
          }
        }
      }
    ]
  }
}

module modRouteTable 'br/public:avm/res/network/route-table:0.2.1' = {
  name: 'Route-Table'
  params: {
    // Required parameters
    name: 'route-to-${paramlocation}-hub-fw'
    // Non-required parameters
    location: paramlocation
    routes: [
      {
        name: 'routeToFirewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.10.3.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module modNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.2' = {
  name: 'Network-Security-Group'
  params: {
    // Required parameters
    name: 'NSG'
    // Non-required parameters
    location: paramlocation
    securityRules: [
      {
        name: 'nsgRule'
        properties: {
          access: 'Allow'
          description: 'description'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

// DNS ZONES //

module modSqlPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'Sql Private DNS Zone module'
  params: {
    // Required parameters
    name: varSqlEndpoint
    // Non-required parameters
    location: paramlocation
    virtualNetworkLinks: [
      {
        registrationEnabled: true
        virtualNetworkResourceId: modHubVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modCoreVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modProdSpokeVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modDevSpokeVirtualNetwork
      }
    ]
  }
}

module modStPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'Storage Account Private DNS Zone module'
  params: {
    // Required parameters
    name: varStEndpoint
    // Non-required parameters
    location: paramlocation
    virtualNetworkLinks: [
      {
        registrationEnabled: true
        virtualNetworkResourceId: modHubVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modCoreVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modProdSpokeVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modDevSpokeVirtualNetwork
      }
    ]
  }
}

module modKvPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'Key Vault Private DNS Zone module'
  params: {
    // Required parameters
    name: varKeyVaultEndpoint
    // Non-required parameters
    location: paramlocation
    virtualNetworkLinks: [
      {
        registrationEnabled: true
        virtualNetworkResourceId: modHubVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modCoreVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modProdSpokeVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modDevSpokeVirtualNetwork
      }
    ]
  }
}

module modAspPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'App Service Plan Private DNS Zone module'
  params: {
    // Required parameters
    name: 'privatelink.azurewebsites.net'
    // Non-required parameters
    location: paramlocation
    virtualNetworkLinks: [
      {
        registrationEnabled: true
        virtualNetworkResourceId: modHubVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modCoreVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modProdSpokeVirtualNetwork
      }
      {
        registrationEnabled: true
        virtualNetworkResourceId: modDevSpokeVirtualNetwork
      }
    ]
  }
}

// BASTION //

module modBastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: 'Bastion'
  params: {
    // Required parameters
    name: 'bas-hub-${paramlocation}-001'
    vNetId: modHubVirtualNetwork.outputs.resourceId
    bastionSubnetPublicIpResourceId: ''
    // Non-required parameters
    location: paramlocation
    skuName: 'Standard'
    publicIPAddressObject: {
      allocationMethod: 'Static'
      name: 'pip-ab-${paramlocation}'
      publicIPPrefixResourceId: ''
      skuName: 'Standard'
    }
  }
}

// VPN Gateway //

module modVirtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.1.0' = {
  name: 'VPN-Gateway'
  params: {
    // Required parameters
    gatewayType: 'Vpn'
    name: 'vgw-hub-${paramlocation}-001'
    skuName: 'VpnGw1'
    vNetResourceId: modHubVirtualNetwork.outputs.resourceId
    // Non-required parameters
    activeActive: true
    enablePrivateIpAddress: true
    location: paramlocation
    vpnGatewayGeneration: 'Generation1'
    vpnType: 'RouteBased'
  }
}

// VM //

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.2.1' = {
  name: 'Core Virtual Machine'
  params: {
    // Required parameters
    adminUsername: 'VMAdmin2'
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    name: 'cvmwinmax'
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        diagnosticSettings: [
          {
            eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
            eventHubName: '<eventHubName>'
            metricCategories: [
              {
                category: 'AllMetrics'
              }
            ]
            name: 'customSetting'
            storageAccountResourceId: '<storageAccountResourceId>'
            workspaceResourceId: '<workspaceResourceId>'
          }
        ]
        ipConfigurations: [
          {
            applicationSecurityGroups: [
              {
                id: '<id>'
              }
            ]
            diagnosticSettings: [
              {
                eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
                eventHubName: '<eventHubName>'
                metricCategories: [
                  {
                    category: 'AllMetrics'
                  }
                ]
                name: 'customSetting'
                storageAccountResourceId: '<storageAccountResourceId>'
                workspaceResourceId: '<workspaceResourceId>'
              }
            ]
            loadBalancerBackendAddressPools: [
              {
                id: '<id>'
              }
            ]
            name: 'ipconfig01'
            pipConfiguration: {
              publicIpNameSuffix: '-pip-01'
            }
            subnetResourceId: '<subnetResourceId>'
            zones: [
              '1'
              '2'
              '3'
            ]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      createOption: 'fromImage'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: 'Standard_DS2_v3'
    // Non-required parameters
    adminPassword: '<adminPassword>'
    availabilityZone: 2
    backupPolicyName: '<backupPolicyName>'
    backupVaultName: '<backupVaultName>'
    backupVaultResourceGroup: '<backupVaultResourceGroup>'
    computerName: 'winvm1'
    enableAutomaticUpdates: true
    encryptionAtHost: false
    extensionAadJoinConfig: {
      enabled: true
    }
    extensionAntiMalwareConfig: {
      enabled: true
    }
    extensionAzureDiskEncryptionConfig: {
      enabled: true
      settings: {
        EncryptionOperation: 'EnableEncryption'
        KeyVaultResourceId: modKeyVault.outputs.resourceId
        KeyVaultURL: modKeyVault.outputs.uri
        ResizeOSDisk: 'false'
        VolumeType: 'All'
      }
    }
    extensionDependencyAgentConfig: {
      enabled: true
    }
    extensionDSCConfig: {
      enabled: true
    }
    extensionMonitoringAgentConfig: {
      enabled: true
      monitoringWorkspaceResourceId: '<monitoringWorkspaceResourceId>'
    }
    extensionNetworkWatcherAgentConfig: {
      enabled: true
    }
    location: paramlocation
    patchMode: 'AutomaticByOS'
  }
}

// CORE KEYVAULT //

module modKeyVault 'br/public:avm/res/key-vault/vault:0.3.4' = {
  name: 'Core Key Vault'
  params: {
    name: 'kv-encrypt-core-21022024'
    enablePurgeProtection: false
    location: paramlocation
    enableVaultForDeployment: true
    enableVaultForTemplateDeployment: true
    enableVaultForDiskEncryption: true
    privateEndpoints: [
      {
        ipConfigurations: [
          {
            name: varKeyVaultEndpoint
            properties: {
              groupId: 'vault'
              memberName: 'default'
              privateIPAddress: '10.0.0.10'
            }
          }
        ]
        privateDnsZoneResourceIds: [
          modKvPrivateDnsZone.outputs.resourceId
        ]
        subnetResourceId: modHubVirtualNetwork.outputs.subnetResourceIds[1]
      }
    ]
  }
}

// App Service + Plan //

module modDevAppServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = {
  name: 'Dev-ASP'
  params: {
    name: 'asp-dev-${paramlocation}-001-12345'
    sku: {
      name: 'S1'
      tier: 'Standard'
    }
    kind: 'Linux'
    location: paramlocation
  }
}

module modProdAppServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = {
  name: 'Prod-ASP'
  params: {
    name: 'asp-prod-${paramlocation}-001-123456'
    sku: {
      name: 'S1'
      tier: 'Standard'
    }
    kind: 'Linux'
    location: paramlocation
  }
}

module modDevAppService 'br/public:avm/res/web/site:0.2.0' = {
  name: 'DevAppService'
  params: {
    kind: 'app'
    name: 'as-dev-${paramlocation}-001-12345'
    serverFarmResourceId: modDevAppServicePlan.outputs.resourceId
    location: paramlocation
    httpsOnly: true
    siteConfig: {
      metadata: [
        {
          name: 'Current_Stack'
          value: 'DOTNETCORE|7.0'
        }
      ]
    }
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modAspPrivateDnsZone.outputs.resourceId
        ]
        subnetResourceId: modDevSpokeVirtualNetwork.outputs.subnetResourceIds[0]
      }
    ]
  }
}

module modProdAppService 'br/public:avm/res/web/site:0.2.0' = {
  name: 'ProdAppService'
  params: {
    kind: 'app'
    name: 'as-prod-${paramlocation}-001-12345'
    serverFarmResourceId: modDevAppServicePlan.outputs.resourceId
    location: paramlocation
    httpsOnly: true
    siteConfig: {
      metadata: [
        {
          name: 'Current_Stack'
          value: 'DOTNETCORE|7.0'
        }
      ]
    }
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modAspPrivateDnsZone.outputs.resourceId
        ]
        subnetResourceId: modProdSpokeVirtualNetwork.outputs.subnetResourceIds[0]
      }
    ]
  }
}

// LOG ANALYTICS WORKSPACE //

module modLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.3.1' = {
  name: 'LogAnalyticsWorkspace'
  params: {
    // Required parameters
    name: 'log-core-${paramlocation}-001-21020242'
    // Non-required parameters
    dailyQuotaGb: 10
    dataSources: [
      {
        eventLogName: 'Application'
        eventTypes: [
          {
            eventType: 'Error'
          }
          {
            eventType: 'Warning'
          }
          {
            eventType: 'Information'
          }
        ]
        kind: 'WindowsEvent'
        name: 'applicationEvent'
      }
      {
        counterName: '% Processor Time'
        instanceName: '*'
        intervalSeconds: 60
        kind: 'WindowsPerformanceCounter'
        name: 'windowsPerfCounter1'
        objectName: 'Processor'
      }
      {
        kind: 'IISLogs'
        name: 'sampleIISLog1'
        state: 'OnPremiseEnabled'
      }
    ]
    diagnosticSettings: [
      {
        eventHubAuthorizationRuleResourceId: '<eventHubAuthorizationRuleResourceId>'
        eventHubName: '<eventHubName>'
        storageAccountResourceId: '<storageAccountResourceId>'
        workspaceResourceId: '<workspaceResourceId>'
      }
    ]
    gallerySolutions: [
      {
        name: 'AzureAutomation'
        product: 'OMSGallery'
        publisher: 'Microsoft'
      }
    ]
    linkedServices: [
      {
        name: 'Automation'
        resourceId: '<resourceId>'
      }
    ]
    linkedStorageAccounts: [
      {
        name: 'Query'
        resourceId: '<resourceId>'
      }
    ]
    location: paramlocation
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    storageInsightsConfigs: [
      {
        storageAccountResourceId: '<storageAccountResourceId>'
        tables: [
          'LinuxsyslogVer2v0'
          'WADETWEventTable'
          'WADServiceFabric*EventTable'
          'WADWindowsEventLogsTable'
        ]
      }
    ]
    useResourcePermissions: true
  }
}

/////////////// OLD PROJECT BELOW HERE \\\\\\\\\\\\\

// PRIVATE DNS ZONE MODULES
module modPrivateDnsZoneKeyVault 'modules/privatednszone.bicep' = {
  name: 'keyvault-privatednszone'
  params: {
    paramPrivateDnsZoneName: varKeyVaultEndpoint
  }
}

module modPrivateDnsZoneSQL 'modules/privatednszone.bicep' = {
  name: 'sql-privatednszone'
  params: {
    paramPrivateDnsZoneName: varSqlEndpoint
  }
}

module modPrivateDnsZoneSt 'modules/privatednszone.bicep' = {
  name: 'storageaccount-privatednszone'
  params: {
    paramPrivateDnsZoneName: varStEndpoint
  }
}

module modPrivateDnsZoneAsp 'modules/privatednszone.bicep' = {
    name: 'appserviceplan-privatednszone'
    params: {
      paramPrivateDnsZoneName: 'privatelink.azurewebsites.net'
    }
  }

// APPLICATION GATEWAY MODULE
module modAgw 'modules/appgw.bicep' = {
    name: 'appgateway'
    params: {
      paramAppGatewayName: 'agw-hub-${paramlocation}-001'
      paramlocation: paramlocation
      paramAgwSubnetId: modHubVirtualNetwork.outputs.subnetResourceIds[1]
      paramProdFqdn: modProd.outputs.outProdFqdn
    }
  }

// LOG ANALYTICS MODULE
  module modLogAnalytics 'modules/loganalytics.bicep' = {
    name: 'loganalytics'
    params: {
      paramLogAnalyticsName: paramLogAnalyticsName
      paramlocation: paramlocation
    }
  }

// // ROUTE TABLE MODULE
// module modRoutes 'modules/routetable.bicep' = {
//   name: 'routetable'
//   params: {
//     paramlocation: paramlocation
//   }
// }

// HUB MODULE
// module modHub 'modules/hub.bicep' = {
//   name: 'hub-${paramlocation}-001'
//   params: {
//     paramlocation: paramlocation
//     workspaceResourceId: modLogAnalytics.outputs.logAnalyticsId
//     paramHubVnet: modHubVirtualNetwork.outputs.resourceId
//     // paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
//     // paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
//     // privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
//     // SqlDbPrivateDnsZoneName: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneName
//   }
// }

// CORE MODULE
module modCore 'modules/core.bicep' = {
  name: 'core-${paramlocation}-001'
  params: {
    paramlocation: paramlocation
    VMusername: resKeyVault.getSecret('VMusername')
    VMpassword: resKeyVault.getSecret('VMpassword')
    resRouteTable: modRouteTable.name
    keyVaultCoreObjectId: keyVaultObjectId
    osType: 'windows'
    storageUri: modProd.outputs.outStorageAccountEndpoint
    paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
    paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
    privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
    SqlDbPrivateDnsZoneName: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneName
    paramKeyVaultPrivateDnsZoneId: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneId
    paramKeyVaultEndpointName: 'kvendpointname'
    paramWorkspaceId: modLogAnalytics.outputs.logAnalyticsId
  }
}

// DEV SPOKE MODULE
module modDev 'modules/spoke.bicep' = {
  name: 'dev-${paramlocation}-001'
  params: {
    paramlocation: paramlocation
    resRouteTable: modRouteTable.name
    paramAppSubnetAddressPrefix: '10.30.1.0/24'
    paramSqlSubnetAddressPrefix: '10.30.2.0/24'
    paramStSubnetAddressPrefix: '10.30.3.0/24'
    paramVnetAddressPrefix: '10.30.0.0/16'
    paramVnetName: 'vnet-dev-${paramlocation}-001'
    paramAspName: 'asp-dev-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
    paramAppServiceName: 'as-dev-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
    paramAppSubnetName: 'devAppServiceSubnet'
    paramSqlSubnetName: 'devSqlSubnet'
    paramStSubnetName: 'devStorageSubnet'
    paramAspNsgName: 'dev-asp-nsg'
    paramSqlNsgName: 'dev-sql-nsg'
    paramStNsgName: 'dev-st-nsg'
    paramSqlServerDatabaseName: 'sqldb-dev-${paramlocation}-001'
    paramSqlServerName: 'sql-dev-${paramlocation}-001-${randNumb}'
    paramSqlUsername: resKeyVault.getSecret('SQLdevusername')
    paramSqlPassword: resKeyVault.getSecret('SQLpassworddev')
    privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
    SqlDbPrivateDnsZoneName: varSqlEndpoint
    paramAspPrivateEndpointName: 'aspDevPrivEndPoint'
    paramSqlDbPrivateEndpointName: 'sqlDevPrivEndPoint'
    paramStorageAccount: 'stdev${randNumb}'
    paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
    paramStPrivateDnsZoneId: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneId
    paramAspPrivateDnsZoneId: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneId
    paramSqlPrivateDnsZoneId: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneId
    paramStPrivateEndpointName: 'stendpoint-dev-${paramlocation}-001'
    paramAppInsightName: paramAppInsightsName
    appName: 'app'
    paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
    paramDept: 'Development'
  }
}

// PROD SPOKE MODULE
module modProd 'modules/spoke.bicep' = {
  name: 'prod-${paramlocation}-001'
  params: {
    paramlocation: paramlocation
    resRouteTable: modRouteTable.name
    paramAppSubnetAddressPrefix: '10.31.1.0/24'
    paramSqlSubnetAddressPrefix: '10.31.2.0/24'
    paramStSubnetAddressPrefix: '10.31.3.0/24'
    paramVnetAddressPrefix: '10.31.0.0/16'
    paramVnetName: 'vnet-prod-${paramlocation}-001'
    paramAspName: 'asp-prod-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
    paramAppServiceName: 'as-prod-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
    paramAppSubnetName: 'prodAppServiceSubnet'
    paramSqlSubnetName: 'prodSqlSubnet'
    paramStSubnetName: 'prodStorageSubnet'
    paramAspNsgName: 'prod-asp-nsg'
    paramSqlNsgName: 'prod-sql-nsg'
    paramStNsgName: 'prod-st-nsg'
    paramSqlServerDatabaseName: 'sqldb-prod-${paramlocation}-001'
    paramSqlServerName: 'sql-prod-${paramlocation}-001-${randNumb}'
    paramSqlUsername: resKeyVault.getSecret('SQLdevusername')
    paramSqlPassword: resKeyVault.getSecret('SQLpasswordprod')
    privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
    SqlDbPrivateDnsZoneName: varSqlEndpoint
    paramAspPrivateEndpointName: 'aspProdPrivEndPoint'
    paramSqlDbPrivateEndpointName: 'sqlProdPrivEndPoint'
    paramStorageAccount: 'stprod${randNumb}'
    paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
    paramStPrivateDnsZoneId: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneId
    paramAspPrivateDnsZoneId: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneId
    paramStPrivateEndpointName: 'stendpoint-prod-${paramlocation}-001'
    paramAppInsightName: paramAppInsightsName
    appName: 'app'
    paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
    paramSqlPrivateDnsZoneId: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneId
    paramDept: 'Production'
  }
}

// RSV MODULE
module modRecoveryVault 'modules/recoveryvault.bicep' = {
  name: 'recoveryservicevault'
  params: {
    paramVaultName: 'rsv-core-${paramlocation}-001'
    vaultStorageType: 'GeoRedundant'
    enableCRR: true
    paramlocation: paramlocation
    paramSourceResourceId: modCore.outputs.outVmId
    paramVMName: modCore.outputs.outVmName
  }
}

resource resKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
}
