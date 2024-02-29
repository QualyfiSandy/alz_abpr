
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
param pCoreSecKeyVaultName string
param pCoreEncryptionKeyVaultName string
param pNICVMIP string
param pVMName string
param pVMComputerName string
param pVMSize string
param pRSVName string
param pDevAppServicePlanName string
param pAppServicePlanSku string
param pAppServicePlanTier string
param pProdAppServicePlanName string
param pDevAppServiceName string
param pProdAppServiceName string
param pLogAnalyticsWorkspaceName string
param pProdSqlServerName string
param pDevSqlServerName string
param pDevSqlDatabaseName string
param pProdSqlDatabaseName string
param pProdStName string
param pDevStName string
param pStKind string
param pStSkuName string
param pAppGatewayName string
param pAppGatewayPIPName string
param pAzureFirewallName string
param pAzureFirewallPIPName string
param pAzureFirewallPolicyName string

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
var vAppGwId = resourceId('Microsoft.Network/applicationGateways',pAppGatewayName)
var vRand = substring(uniqueString(resourceGroup().id),0,5)

resource coreSecKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: pCoreSecKeyVaultName
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
    name: 'DefaultNSG'
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
    adminUsername: coreSecKeyVault.getSecret('VMusername')
    adminPassword: coreSecKeyVault.getSecret('VMpassword')
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
      diskSizeGB: '256'
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    backupPolicyName: 'DefaultPolicy'
    backupVaultName: modRecoveryServiceVault.outputs.name
    backupVaultResourceGroup: modRecoveryServiceVault.outputs.resourceGroupName
    enableAutomaticUpdates: true
    encryptionAtHost: false
    extensionAntiMalwareConfig: {
      enabled: true
      settings: {
        AntimalwareEnabled: 'true'
      }
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

// VM INSIGHTS //

module solution 'br/public:avm/res/operations-management/solution:0.1.2' = {
  name: 'VMInsights'
  params: {
    logAnalyticsWorkspaceName: modLogAnalyticsWorkspace.outputs.name
    name: 'VMInsights'
    location: pLocation
    product: 'OMSGallery/VMInsights'
    publisher: 'Microsoft'
  }
}

// DATA COLLECTION RULE //

module dataCollectionRule 'br/public:avm/res/insights/data-collection-rule:0.1.2' = {
  name: 'DataCollectionRule'
  params: {
    name: 'Data-Collection-Rule'
    description: 'Collecting Windows-specific performance counters and Windows Event Logs'
    kind: 'Windows'
    location: pLocation
    dataFlows: [
      {
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
        streams: [
          'Microsoft-InsightsMetrics'
        ]
      }
      {
        destinations: [
          modLogAnalyticsWorkspace.name
        ]
        streams: [
          'Microsoft-Event'
        ]
      }
    ]
    dataSources: {
      performanceCounters: [
        {
          counterSpecifiers: [
            '\\LogicalDisk(_Total)\\% Disk Read Time'
            '\\LogicalDisk(_Total)\\% Disk Time'
            '\\LogicalDisk(_Total)\\% Disk Write Time'
            '\\LogicalDisk(_Total)\\% Free Space'
            '\\LogicalDisk(_Total)\\% Idle Time'
            '\\LogicalDisk(_Total)\\Avg. Disk Queue Length'
            '\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Read'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer'
            '\\LogicalDisk(_Total)\\Avg. Disk sec/Write'
            '\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length'
            '\\LogicalDisk(_Total)\\Disk Bytes/sec'
            '\\LogicalDisk(_Total)\\Disk Read Bytes/sec'
            '\\LogicalDisk(_Total)\\Disk Reads/sec'
            '\\LogicalDisk(_Total)\\Disk Transfers/sec'
            '\\LogicalDisk(_Total)\\Disk Write Bytes/sec'
            '\\LogicalDisk(_Total)\\Disk Writes/sec'
            '\\LogicalDisk(_Total)\\Free Megabytes'
            '\\Memory\\% Committed Bytes In Use'
            '\\Memory\\Available Bytes'
            '\\Memory\\Cache Bytes'
            '\\Memory\\Committed Bytes'
            '\\Memory\\Page Faults/sec'
            '\\Memory\\Pages/sec'
            '\\Memory\\Pool Nonpaged Bytes'
            '\\Memory\\Pool Paged Bytes'
            '\\Network Interface(*)\\Bytes Received/sec'
            '\\Network Interface(*)\\Bytes Sent/sec'
            '\\Network Interface(*)\\Bytes Total/sec'
            '\\Network Interface(*)\\Packets Outbound Errors'
            '\\Network Interface(*)\\Packets Received Errors'
            '\\Network Interface(*)\\Packets Received/sec'
            '\\Network Interface(*)\\Packets Sent/sec'
            '\\Network Interface(*)\\Packets/sec'
            '\\Process(_Total)\\Handle Count'
            '\\Process(_Total)\\Thread Count'
            '\\Process(_Total)\\Working Set'
            '\\Process(_Total)\\Working Set - Private'
            '\\Processor Information(_Total)\\% Privileged Time'
            '\\Processor Information(_Total)\\% Processor Time'
            '\\Processor Information(_Total)\\% User Time'
            '\\Processor Information(_Total)\\Processor Frequency'
            '\\System\\Context Switches/sec'
            '\\System\\Processes'
            '\\System\\Processor Queue Length'
            '\\System\\System Up Time'
          ]
          name: 'perfCounterDataSource60'
          samplingFrequencyInSeconds: 60
          streams: [
            'Microsoft-InsightsMetrics'
          ]
        }
      ]
      windowsEventLogs: [
        {
          name: 'WinLogEvents'
          streams: [
            'Microsoft-Event'
          ]
          xPathQueries: [
            'Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]'
            'Security!*[System[(band(Keywords,13510798882111488))]]'
            'System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=0 or Level=5)]]'
          ]
        }
      ]
    }
    destinations: {
      azureMonitorMetrics: {
        name: 'VMInsightsPerf-Logs-Dest'
      }
      logAnalytics: [
        {
          name: modLogAnalyticsWorkspace.name
          workspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId
        }
      ]
    }
  }
}

// CORE KEYVAULT //

module modEncryptionKeyVault 'br/public:avm/res/key-vault/vault:0.3.4' = {
  name: 'CoreEcryptionKeyVault'
  params: {
    name: '${pCoreEncryptionKeyVaultName}${vRand}'
    sku: 'standard'
    enableRbacAuthorization: false
    enablePurgeProtection: false
    location: pLocation
    enableVaultForDeployment: true
    enableVaultForTemplateDeployment: true
    enableVaultForDiskEncryption: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    privateEndpoints: [
      {
        privateDnsZoneResourceIds: [
          modKvPrivateDnsZone.outputs.resourceId
        ]
        service: 'vault'
        subnetResourceId: modCoreVirtualNetwork.outputs.subnetResourceIds[1]
      }
    ]
  }
}

// App Service + Plan //

module modDevAppServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = {
  name: 'DevAppServicePlan'
  params: {
    name: pDevAppServicePlanName
    sku: {
      name: pAppServicePlanSku
      tier: pAppServicePlanTier
    }
    kind: 'Linux'
    location: pLocation
  }
}

module modProdAppServicePlan 'br/public:avm/res/web/serverfarm:0.1.0' = {
  name: 'ProdAppServicePlan'
  params: {
    name: pProdAppServicePlanName
    sku: {
      name: pAppServicePlanSku
      tier: pAppServicePlanTier
    }
    kind: 'Linux'
    location: pLocation
  }
}

module modDevAppService 'br/public:avm/res/web/site:0.2.0' = {
  name: 'DevAppService'
  params: {
    kind: 'app'
    name: pDevAppServiceName
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
    name: pProdAppServiceName
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
    name: 'App-Insights'
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
    name: pLogAnalyticsWorkspaceName
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
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    useResourcePermissions: true
  }
}

// SQL SERVER //

module modProdSqlServer 'br/public:avm/res/sql/server:0.1.5' = {
  name: 'ProdSQLServer'
  params: {
    name: '${pProdSqlServerName}${vRand}'
    administratorLogin: 'usersandy'
    administratorLoginPassword: 'GoodbyeMonkey987!'
    location: pLocation
    databases: [
      {
        name: '${pProdSqlDatabaseName}${vRand}'
        skuName: 'Basic'
        skuTier: 'Basic'
        maxSizeBytes: 2147483648
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
    name: '${pDevSqlServerName}${vRand}'
    administratorLogin: 'sandyuser1'
    administratorLoginPassword: 'HelloMonkey123!'
    location: pLocation
    databases: [
      {
        name: '${pDevSqlDatabaseName}${vRand}'
        skuName: 'Basic'
        skuTier: 'Basic'
        maxSizeBytes: 2147483648
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
    name: pProdStName
    kind: pStKind
    skuName: pStSkuName
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
    name: pDevStName
    kind: pStKind
    skuName: pStSkuName
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

module modsrcctrl './modules/srcctrl.bicep' = {
  name: 'src-control'
  // dependsOn: [modDevAppService]
  params: {
    paramsrcctrlname: '${modDevAppService.outputs.name}/web'
  }
}

// APPLICATION GATEWAY //

module applicationGateway './ResourceModules/modules/network/application-gateway/main.bicep' = {
  name: 'ApplicationGateway'
  params: {
    name: pAppGatewayName
    location: pLocation
    sku: 'Standard_v2'
    autoscaleMaxCapacity: 2
    autoscaleMinCapacity: 1
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-configuration'
        properties: {
          subnet: {
            id: modHubVirtualNetwork.outputs.subnetResourceIds[1]
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appgw-frontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: modAppGatewayPIP.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServiceBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: modProdAppService.outputs.defaultHostname
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceBackendHttpSetting'
        properties: {
          cookieBasedAffinity: 'Disabled'
          port: 80
          protocol: 'Http'
        }
      }
    ]
    httpListeners: [
      {
        name: 'httplisteners'
        properties: {
          frontendIPConfiguration: {
            id: '${vAppGwId}/frontendIPConfigurations/appgw-frontendIP'
          }
          frontendPort: {
            id: '${vAppGwId}/frontendPorts/port80'
          }
          protocol: 'http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingrules'
        properties: {
          ruleType: 'Basic'
          priority: 110
          backendAddressPool: {
            id: '${vAppGwId}/backendAddressPools/appServiceBackendPool'
          }
          backendHttpSettings: {
            id: '${vAppGwId}/backendHttpSettingsCollection/appServiceBackendHttpSetting'
          }
          httpListener: {
            id: '${vAppGwId}/httpListeners/httplisteners'
          }
        }
      }
    ]
  }
}

module modAppGatewayPIP 'br/public:avm/res/network/public-ip-address:0.2.2' = {
  name:'AppGatewayPip'
  params:{
    name: pAppGatewayPIPName
    location:pLocation
    skuName: 'Standard'
    publicIPAllocationMethod:'Static'
  }
}

// RECOVERY SERVICES VAULT //

module modRecoveryServiceVault './ResourceModules/modules/recovery-services/vault/main.bicep' = {
  name: 'RecoveryServiceVault'
  params: {
    name: pRSVName
    location: pLocation
  }
}

// AZURE FIREWALL //

module azureFirewall './ResourceModules/modules/network/azure-firewall/main.bicep' = {
  name: 'AzureFirewall'
  params: {
    name: pAzureFirewallName
    location: pLocation
    firewallPolicyId: firewallPolicy.outputs.resourceId
    publicIPAddressObject: {
      diagnosticSettings: [
        {
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          name: 'customSetting'
          workspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId
        }
      ]
      name: pAzureFirewallPIPName
      publicIPAllocationMethod: 'Static'
      publicIPPrefixResourceId: ''
      skuName: 'Standard'
      skuTier: 'Regional'
    }
    vNetId: modHubVirtualNetwork.outputs.resourceId
  }
}

// AZURE FIREWALL POLICY //

module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.1.1' = {
  name: 'AzureFirewallPolicy'
  params: {
    name: pAzureFirewallPolicyName
    location: pLocation
    ruleCollectionGroups: [
      {
        name: 'DefaultNetworkRuleCollectionGroup'
        priority: 200
        ruleCollections: [
          {
            action: {
              type: 'Allow'
            }
            name: 'AllowAll'
            priority: 100
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                name: 'afwAllowAll'
                ruleType: 'NetworkRule'
                ipProtocols: [
                  'Any'
                ]
                sourceAddresses: [
                  '*'
                ]
                destinationAddresses: [
                  '*'
                ]
                destinationPorts: [
                  '*'
                ]
              }
            ]
          }
        ]
      }
    ]
    threatIntelMode: 'Alert'
  }
}
