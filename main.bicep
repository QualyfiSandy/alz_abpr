
param pLocation string

param pHubVnetName string
param pCoreVnetName string
param pDevVnetName string
param pProdVnetName string
param pGatewaySubnetName string
param pAppGwSubnetName string
param pAzureFirewallSubnetName string
param pBastionSubnetName string
param pVMSubnetName string
param pKVSubnetName string
param pAppSubnetName string
param pSqlSubnetName string
param pStSubnetName string
param pRouteTableName string
param pBastionName string
param pBastionPIPName string
param pVPNGatewayName string
param pCoreSecretKeyVaultName string
param pCoreEncryptionKeyVaultName string
param pNICVMIP string
param pVMName string
param pVMComputerName string
param pVMSize string

param pVPNGatewayType string
param pVPNGatewaySkuName string
param pVPNGatewayPIPName string

param pHubVnetAddressPrefix string
param pCoreVnetAddressPrefix string
param pDevVnetAddressPrefix string
param pProdVnetAddressPrefix string

var vHubVnetAddress = '${pHubVnetAddressPrefix}.0.0/16'
var vGatewaySubnetAddress = '${pHubVnetAddressPrefix}.1.0/24'
var vAppGwSubnetAddress = '${pHubVnetAddressPrefix}.2.0/24'
var vAzureFirewallSubnetAddress = '${pHubVnetAddressPrefix}.3.0/24'
var vBastionSubnetAddress = '${pHubVnetAddressPrefix}.4.0/24'

var vCoreVnetAddress = '${pCoreVnetAddressPrefix}.0.0/16'
var vVMSubnetAddress = '${pCoreVnetAddressPrefix}.1.0/24'
var vKVSubnetAddress = '${pCoreVnetAddressPrefix}.2.0/24'

var vDevVnetAddress = '${pDevVnetAddressPrefix}.0.0/16'
var vDevAspAddress = '${pDevVnetAddressPrefix}.1.0/24'
var vDevSqlAddress = '${pDevVnetAddressPrefix}.2.0/24'
var vDevStAddress = '${pDevVnetAddressPrefix}.3.0/24'

var vProdVnetAddress = '${pProdVnetAddressPrefix}.0.0/16'
var vProdAspAddress = '${pProdVnetAddressPrefix}.1.0/24'
var vProdSqlAddress = '${pProdVnetAddressPrefix}.2.0/24'
var vProdStAddress = '${pProdVnetAddressPrefix}.3.0/24'

var varSqlEndpoint = 'privatelink${environment().suffixes.sqlServerHostname}'
var varKeyVaultEndpoint = 'privatelink${environment().suffixes.keyvaultDns}'
var varStEndpoint = 'privatelink.blob.${environment().suffixes.storage}'

resource coreSecretKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: pCoreSecretKeyVaultName
}

// VIRTUAL NETWORKS //

module modHubVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'HubVirtualNetwork'
  params: {
    name: pHubVnetName
    // Required parameters
    addressPrefixes: [
      vHubVnetAddress
    ]
    // Non-required parameters
    location: pLocation
    subnets: [
      {
        addressPrefix: vGatewaySubnetAddress
        name: pGatewaySubnetName
      }
      {
        addressPrefix: vAppGwSubnetAddress
        name: pAppGwSubnetName
      }
      {
        addressPrefix: vAzureFirewallSubnetAddress
        name: pAzureFirewallSubnetName
      }
      {
        addressPrefix: vBastionSubnetAddress
        name: pBastionSubnetName
      }
    ]
  }
}

module modCoreVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'CoreVirtualNetwork'
  params: {
    // Required parameters
    addressPrefixes: [
      vCoreVnetAddress
    ]
    name: pCoreVnetName
    // Non-required parameters
    location: pLocation
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
        addressPrefix: vVMSubnetAddress
        name: pVMSubnetName
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
      {
        addressPrefix: vKVSubnetAddress
        name: pKVSubnetName
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
    ]
  }
}

module modDevSpokeVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'DevVirtualNetwork'
  params: {
    // Required parameters
    addressPrefixes: [
      vDevVnetAddress
    ]
    name: pDevVnetName
    // Non-required parameters
    location: pLocation
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
        name: pAppSubnetName
        addressPrefix: vDevAspAddress
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
      {
        name: pSqlSubnetName
        addressPrefix: vDevSqlAddress
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
      {
        name: pStSubnetName
        addressPrefix: vDevStAddress
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
    ]
  }
}

module modProdSpokeVirtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  name: 'ProdVirtualNetwork'
  params: {
    addressPrefixes: [
      vProdVnetAddress
    ]
    name: pProdVnetName
    location: pLocation
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
        name: pAppSubnetName
        addressPrefix: vProdAspAddress
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
      {
        name: pSqlSubnetName
        addressPrefix: vProdSqlAddress
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
      {
        name: pStSubnetName
        addressPrefix: vProdStAddress
        networkSecurityGroupResourceId: modNetworkSecurityGroup.outputs.resourceId
        routeTableResourceId: modRouteTable.outputs.resourceId
      }
    ]
  }
}

module modRouteTable 'br/public:avm/res/network/route-table:0.2.1' = {
  name: 'RouteTable'
  params: {
    // Required parameters
    name: pRouteTableName
    // Non-required parameters
    location: pLocation
    routes: [
      {
        name: 'defaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.10.3.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'coreRoute'
        properties: {
          addressPrefix: vCoreVnetAddress
          nextHopIpAddress: '10.10.3.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'devRoute'
        properties: {
          addressPrefix: vDevVnetAddress
          nextHopIpAddress: '10.10.3.4'
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'prodRoute'
        properties: {
          addressPrefix: vProdVnetAddress
          nextHopIpAddress: '10.10.3.4'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module modNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.1.2' = {
  name: 'NetworkSecurityGroup'
  params: {
    // Required parameters
    name: 'Default NSG'
    // Non-required parameters
    location: pLocation
    securityRules: [
      {
        name: 'defaultRule'
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
  name: 'SqlPrivateDNSZone'
  params: {
    // Required parameters
    name: varSqlEndpoint
    // Non-required parameters
    virtualNetworkLinks: [
      {
        name: 'hub-link'
        registrationEnabled: false
        virtualNetworkResourceId: modHubVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'core-link'
        registrationEnabled: false
        virtualNetworkResourceId: modCoreVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'prod-link'
        registrationEnabled: false
        virtualNetworkResourceId: modProdSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'dev-link'
        registrationEnabled: false
        virtualNetworkResourceId: modDevSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
    ]
  }
}

module modStPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'StorageAccountPrivateDNSZone'
  params: {
    // Required parameters
    name: varStEndpoint
    // Non-required parameters
    virtualNetworkLinks: [
      {
        name: 'hub-link'
        registrationEnabled: false
        virtualNetworkResourceId: modHubVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'core-link'
        registrationEnabled: false
        virtualNetworkResourceId: modCoreVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'prod-link'
        registrationEnabled: false
        virtualNetworkResourceId: modProdSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'dev-link'
        registrationEnabled: false
        virtualNetworkResourceId: modDevSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
    ]
  }
}

module modKvPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'KeyVaultPrivateDNSZone'
  params: {
    // Required parameters
    name: varKeyVaultEndpoint
    // Non-required parameters
    virtualNetworkLinks: [
      {
        name: 'hub-link'
        registrationEnabled: false
        virtualNetworkResourceId: modHubVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'core-link'
        registrationEnabled: false
        virtualNetworkResourceId: modCoreVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'prod-link'
        registrationEnabled: false
        virtualNetworkResourceId: modProdSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'dev-link'
        registrationEnabled: false
        virtualNetworkResourceId: modDevSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
    ]
  }
}

module modAspPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.3' = {
  name: 'AppServicePlanPrivateDNSZone'
  params: {
    // Required parameters
    name: 'privatelink.azurewebsites.net'
    // Non-required parameters
    virtualNetworkLinks: [
      {
        name: 'hub-link'
        registrationEnabled: false
        virtualNetworkResourceId: modHubVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'core-link'
        registrationEnabled: false
        virtualNetworkResourceId: modCoreVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'prod-link'
        registrationEnabled: false
        virtualNetworkResourceId: modProdSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
      {
        name: 'dev-link'
        registrationEnabled: false
        virtualNetworkResourceId: modDevSpokeVirtualNetwork.outputs.resourceId
        location: 'global'
      }
    ]
  }
}

// BASTION //

module modBastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  name: 'Bastion'
  params: {
    name: pBastionName
    vNetId: modHubVirtualNetwork.outputs.resourceId
    location: pLocation
    skuName: 'Standard'
    publicIPAddressObject: {
      allocationMethod: 'Static'
      name: pBastionPIPName
      skuName: 'Standard'
    }
  }
}

// VPN Gateway //

module modVirtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.1.0' = {
  name: 'VPNGateway'
  params: {
    gatewayType: pVPNGatewayType
    name: pVPNGatewayName
    skuName: pVPNGatewaySkuName
    vNetResourceId: modHubVirtualNetwork.outputs.resourceId
    location: pLocation
    gatewayPipName: pVPNGatewayPIPName
  }
}

// VM //

module modCoreVirtualMachine 'br/public:avm/res/compute/virtual-machine:0.2.1' = {
  name: 'VirtualMachine'
  params: {
    name: pVMName
    adminUsername: coreSecretKeyVault.getSecret('VMusername')
    adminPassword: coreSecretKeyVault.getSecret('VMpassword')
    computerName: pVMComputerName
    osType: 'Windows'
    vmSize: pVMSize
    patchMode: 'AutomaticByOS'
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    nicConfigurations: [
      {
        deleteOption: 'Delete'
        ipConfigurations: [
          {
            name: 'ipconfigVM'
            privateIPAllocationMethod: 'Static'
            privateIPAddress: pNICVMIP
            subnetResourceId: modCoreVirtualNetwork.outputs.subnetResourceIds[0]
          }
        ]
        nicSuffix: '-nic'
      }
    ]
    osDisk: {
      createOption: 'fromImage'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    backupPolicyName: '<backupPolicyName>'
    backupVaultName: '<backupVaultName>'
    backupVaultResourceGroup: '<backupVaultResourceGroup>'
    enableAutomaticUpdates: true
    encryptionAtHost: false
    extensionAntiMalwareConfig: {
      enabled: true
    }
    extensionAzureDiskEncryptionConfig: {
      enabled: true
      settings: {
        EncryptionOperation: 'EnableEncryption'
        KeyVaultResourceId: modEncryptionKeyVault.outputs.resourceId
        KeyVaultURL: modEncryptionKeyVault.outputs.uri
        ResizeOSDisk: 'false'
        VolumeType: 'All'
      }
    }
    extensionDependencyAgentConfig: {
      enabled: true
    }
    extensionMonitoringAgentConfig: {
      enabled: true
      monitoringWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId
    }
    location: pLocation
  }
}

// CORE KEYVAULT //

module modEncryptionKeyVault 'br/public:avm/res/key-vault/vault:0.3.4' = {
  name: 'CoreEcryptionKeyVault'
  params: {
    name: pCoreEncryptionKeyVaultName
    sku: 'standard'
    enableRbacAuthorization: false
    enablePurgeProtection: false
    location: pLocation
    enableVaultForDeployment: true
    enableVaultForTemplateDeployment: true
    enableVaultForDiskEncryption: true
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modKvPrivateDnsZone.outputs.resourceId
        ]
        service: 'vault'
        subnetResourceId: modHubVirtualNetwork.outputs.subnetResourceIds[1]
      }
    ]
  }
}

// App Service + Plan //

module modDevAppServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = {
  name: 'Dev-ASP'
  params: {
    name: 'asp-dev-${pLocation}-001-12345'
    sku: {
      name: 'S1'
      tier: 'Standard'
    }
    kind: 'Linux'
    location: pLocation
  }
}

module modProdAppServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = {
  name: 'Prod-ASP'
  params: {
    name: 'asp-prod-${pLocation}-001-123456'
    sku: {
      name: 'S1'
      tier: 'Standard'
    }
    kind: 'Linux'
    location: pLocation
  }
}

module modDevAppService 'br/public:avm/res/web/site:0.2.0' = {
  name: 'DevAppService'
  params: {
    kind: 'app'
    name: 'as-dev-${pLocation}-001-12345'
    serverFarmResourceId: modDevAppServicePlan.outputs.resourceId
    location: pLocation
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
    name: 'as-prod-${pLocation}-001-12345'
    serverFarmResourceId: modDevAppServicePlan.outputs.resourceId
    location: pLocation
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

module modAppInsights 'br/public:avm/res/insights/component:0.2.0' = {
  name: 'appInsights'
  params: {
    // Required parameters
    name: 'App Insights'
    workspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId
    // Non-required parameters
    location: pLocation
    kind: 'web'
  }
}

// LOG ANALYTICS WORKSPACE //

module modLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.3.1' = {
  name: 'LogAnalyticsWorkspace'
  params: {
    // Required parameters
    name: 'log-core-${pLocation}-001-21020242'
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
    gallerySolutions: [
      {
        name: 'AzureAutomation'
        product: 'OMSGallery'
        publisher: 'Microsoft'
      }
    ]
    location: pLocation
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    useResourcePermissions: true
  }
}

// SQL SERVER //

module modProdSqlServer 'br/public:avm/res/sql/server:0.1.5' = {
  name: 'ProdSQLServer'
  params: {
    // Required parameters
    name: 'sql-prod-${pLocation}-001-21022024'
    // Non-required parameters
    administratorLogin: 'adminUserName'
    administratorLoginPassword: '<administratorLoginPassword>'
    location: pLocation
    databases: [
      {
        skuName: 'Basic'
        skuTier: 'Basic'
      }
    ]
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modSqlPrivateDnsZone.outputs.resourceId
        ]
        subnetResourceId: modProdSpokeVirtualNetwork.outputs.subnetResourceIds[1]
      }
    ]
  }
}

module modDevSqlServer 'br/public:avm/res/sql/server:0.1.5' = {
  name: 'DevSQLServer'
  params: {
    // Required parameters
    name: 'sql-dev-${pLocation}-001-210220242'
    // Non-required parameters
    administratorLogin: 'adminUserName'
    administratorLoginPassword: '<administratorLoginPassword>'
    location: pLocation
    databases: [
      {
        skuName: 'Basic'
        skuTier: 'Basic'
      }
    ]
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modSqlPrivateDnsZone.outputs.resourceId
        ]
        subnetResourceId: modDevSpokeVirtualNetwork.outputs.subnetResourceIds[1]
      }
    ]
  }
}

module modProdStorageAccount 'br/public:avm/res/storage/storage-account:0.6.2' = {
  name: 'ProdStorageAccount'
  params: {
    // Required parameters
    name: 'stprod00121022024'
    // Non-required parameters
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    location: pLocation
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modStPrivateDnsZone.outputs.resourceId
        ]
        service: 'blob'
        subnetResourceId: modProdSpokeVirtualNetwork.outputs.subnetResourceIds[2]
      }
    ]
  }
}

module modDevStorageAccount 'br/public:avm/res/storage/storage-account:0.6.2' = {
  name: 'DevStorageAccount'
  params: {
    // Required parameters
    name: 'stdev00121022024'
    // Non-required parameters
    kind: 'StorageV2'
    skuName: 'Standard_LRS'
    location: pLocation
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modStPrivateDnsZone.outputs.resourceId
        ]
        service: 'blob'
        subnetResourceId: modDevSpokeVirtualNetwork.outputs.subnetResourceIds[2]
      }
    ]
  }
}

// <--- SOURCE CONTROL ---> //

module modsrcctrl 'srcctrl.bicep' = {
  name: 'src-control'
  // dependsOn: [modDevAppService]
  params: {
    paramsrcctrlname: '${modDevAppService.outputs.name}/web'
  }
}

// RECOVERY SERVICES VAULT //

module vault './ResourceModules/modules/recovery-services/vault/main.bicep' = {
  name: '${uniqueString(deployment().name, location)}-test-rsvmin'
  params: {
    // Required parameters
    name: 'rsvmin001'
    // Non-required parameters
    enableDefaultTelemetry: '<enableDefaultTelemetry>'
  }
}

/////////////// OLD PROJECT BELOW HERE \\\\\\\\\\\\\

// PRIVATE DNS ZONE MODULES
// module modPrivateDnsZoneKeyVault 'modules/privatednszone.bicep' = {
//   name: 'keyvault-privatednszone'
//   params: {
//     paramPrivateDnsZoneName: varKeyVaultEndpoint
//   }
// }

// module modPrivateDnsZoneSQL 'modules/privatednszone.bicep' = {
//   name: 'sql-privatednszone'
//   params: {
//     paramPrivateDnsZoneName: varSqlEndpoint
//   }
// }

// module modPrivateDnsZoneSt 'modules/privatednszone.bicep' = {
//   name: 'storageaccount-privatednszone'
//   params: {
//     paramPrivateDnsZoneName: varStEndpoint
//   }
// }

// module modPrivateDnsZoneAsp 'modules/privatednszone.bicep' = {
//     name: 'appserviceplan-privatednszone'
//     params: {
//       paramPrivateDnsZoneName: 'privatelink.azurewebsites.net'
//     }
//   }

// APPLICATION GATEWAY MODULE
module modAgw 'modules/appgw.bicep' = {
    name: 'appgateway'
    params: {
      paramAppGatewayName: 'agw-hub-${pLocation}-001'
      paramlocation: pLocation
      paramAgwSubnetId: modHubVirtualNetwork.outputs.subnetResourceIds[1]
      paramProdFqdn: modProdAppService.outputs.defaultHostname
    }
  }

// // LOG ANALYTICS MODULE
//   module modLogAnalytics 'modules/loganalytics.bicep' = {
//     name: 'loganalytics'
//     params: {
//       paramLogAnalyticsName: paramLogAnalyticsName
//       paramlocation: paramlocation
//     }
//   }

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
// module modCore 'modules/core.bicep' = {
//   name: 'core-${paramlocation}-001'
//   params: {
//     paramlocation: paramlocation
//     VMusername: resKeyVault.getSecret('VMusername')
//     VMpassword: resKeyVault.getSecret('VMpassword')
//     resRouteTable: modRouteTable.name
//     keyVaultCoreObjectId: keyVaultObjectId
//     osType: 'windows'
//     storageUri: modProd.outputs.outStorageAccountEndpoint
//     paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
//     paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
//     privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
//     SqlDbPrivateDnsZoneName: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneName
//     paramKeyVaultPrivateDnsZoneId: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneId
//     paramKeyVaultEndpointName: 'kvendpointname'
//     paramWorkspaceId: modLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
//   }
// }

// DEV SPOKE MODULE
// module modDev 'modules/spoke.bicep' = {
//   name: 'dev-${paramlocation}-001'
//   params: {
//     paramlocation: paramlocation
//     resRouteTable: modRouteTable.name
//     paramAppSubnetAddressPrefix: '10.30.1.0/24'
//     paramSqlSubnetAddressPrefix: '10.30.2.0/24'
//     paramStSubnetAddressPrefix: '10.30.3.0/24'
//     paramVnetAddressPrefix: '10.30.0.0/16'
//     paramVnetName: 'vnet-dev-${paramlocation}-001'
//     paramAspName: 'asp-dev-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
//     paramAppServiceName: 'as-dev-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
//     paramAppSubnetName: 'devAppServiceSubnet'
//     paramSqlSubnetName: 'devSqlSubnet'
//     paramStSubnetName: 'devStorageSubnet'
//     paramAspNsgName: 'dev-asp-nsg'
//     paramSqlNsgName: 'dev-sql-nsg'
//     paramStNsgName: 'dev-st-nsg'
//     paramSqlServerDatabaseName: 'sqldb-dev-${paramlocation}-001'
//     paramSqlServerName: 'sql-dev-${paramlocation}-001-${randNumb}'
//     paramSqlUsername: resKeyVault.getSecret('SQLdevusername')
//     paramSqlPassword: resKeyVault.getSecret('SQLpassworddev')
//     privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
//     SqlDbPrivateDnsZoneName: varSqlEndpoint
//     paramAspPrivateEndpointName: 'aspDevPrivEndPoint'
//     paramSqlDbPrivateEndpointName: 'sqlDevPrivEndPoint'
//     paramStorageAccount: 'stdev${randNumb}'
//     paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
//     paramStPrivateDnsZoneId: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneId
//     paramAspPrivateDnsZoneId: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneId
//     paramSqlPrivateDnsZoneId: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneId
//     paramStPrivateEndpointName: 'stendpoint-dev-${paramlocation}-001'
//     paramAppInsightName: paramAppInsightsName
//     appName: 'app'
//     paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
//     paramDept: 'Development'
//   }
// }

// // PROD SPOKE MODULE
// module modProd 'modules/spoke.bicep' = {
//   name: 'prod-${paramlocation}-001'
//   params: {
//     paramlocation: paramlocation
//     resRouteTable: modRouteTable.name
//     paramAppSubnetAddressPrefix: '10.31.1.0/24'
//     paramSqlSubnetAddressPrefix: '10.31.2.0/24'
//     paramStSubnetAddressPrefix: '10.31.3.0/24'
//     paramVnetAddressPrefix: '10.31.0.0/16'
//     paramVnetName: 'vnet-prod-${paramlocation}-001'
//     paramAspName: 'asp-prod-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
//     paramAppServiceName: 'as-prod-${paramlocation}-001-${uniqueString(resourceGroup().id)}'
//     paramAppSubnetName: 'prodAppServiceSubnet'
//     paramSqlSubnetName: 'prodSqlSubnet'
//     paramStSubnetName: 'prodStorageSubnet'
//     paramAspNsgName: 'prod-asp-nsg'
//     paramSqlNsgName: 'prod-sql-nsg'
//     paramStNsgName: 'prod-st-nsg'
//     paramSqlServerDatabaseName: 'sqldb-prod-${paramlocation}-001'
//     paramSqlServerName: 'sql-prod-${paramlocation}-001-${randNumb}'
//     paramSqlUsername: resKeyVault.getSecret('SQLdevusername')
//     paramSqlPassword: resKeyVault.getSecret('SQLpasswordprod')
//     privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
//     SqlDbPrivateDnsZoneName: varSqlEndpoint
//     paramAspPrivateEndpointName: 'aspProdPrivEndPoint'
//     paramSqlDbPrivateEndpointName: 'sqlProdPrivEndPoint'
//     paramStorageAccount: 'stprod${randNumb}'
//     paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
//     paramStPrivateDnsZoneId: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneId
//     paramAspPrivateDnsZoneId: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneId
//     paramStPrivateEndpointName: 'stendpoint-prod-${paramlocation}-001'
//     paramAppInsightName: paramAppInsightsName
//     appName: 'app'
//     paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
//     paramSqlPrivateDnsZoneId: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneId
//     paramDept: 'Production'
//   }
// }

// RSV MODULE
module modRecoveryVault 'modules/recoveryvault.bicep' = {
  name: 'recoveryservicevault'
  params: {
    paramVaultName: 'rsv-core-${pLocation}-001'
    vaultStorageType: 'GeoRedundant'
    enableCRR: true
    paramlocation: pLocation
    paramSourceResourceId: modCoreVirtualMachine.outputs.resourceId
    paramVMName: modCoreVirtualMachine.name
  }
}

// resource resKeyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
//   name: keyVaultName
// }
