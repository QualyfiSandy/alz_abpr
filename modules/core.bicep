@secure()
param VMusername string

@secure()
param VMpassword string

param resRouteTable string
param paramlocation string = resourceGroup().location
param tenantId string = subscription().tenantId
param keyVaultCoreObjectId string
param randNumb string
param storageUri string
param paramStPrivateDnsZoneName string
param SqlDbPrivateDnsZoneName string
param privateAspDnsZoneName string
param paramKeyVaultPrivateDnsZoneName string
param paramKeyVaultPrivateDnsZoneId string
param paramKeyVaultEndpointName string
param osType string
param paramWorkspaceId string

var DaExtensionName = ((toLower(osType) == 'windows') ? 'DependencyAgentWindows' : 'DependencyAgentLinux')
var DaExtensionType = ((toLower(osType) == 'windows') ? 'DependencyAgentWindows' : 'DependencyAgentLinux')
var DaExtensionVersion = '9.5'

// <-- CORE VIRTUAL NETWORK --> //
resource resCoreVnet 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: 'vnet-core-${paramlocation}-001'
  location: paramlocation
  tags: {
    Owner: 'Sandy'
    Dept: 'Infrastructure'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'vmSubnet'
        properties: {
          addressPrefix: '10.20.1.0/24'
          networkSecurityGroup: {
            id: vmCoreNetworkSecurityGroup.id
          }
          routeTable: {
            id: resRouteTable
          }
        }
      }
      {
        name: 'KVSubnet'
        properties: {
          addressPrefix: '10.20.2.0/24'
          networkSecurityGroup: {
            id: kvCoreNetworkSecurityGroup.id
        }
        routeTable: {
          id: resRouteTable
        }
      }
      }
    ]
  }
}

resource resStDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${paramStPrivateDnsZoneName}/${resCoreVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resCoreVnet.id
    }
  }
}

resource resSqlDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${SqlDbPrivateDnsZoneName}/${resCoreVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resCoreVnet.id
    }
  }
}

resource resAspDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateAspDnsZoneName}/${resCoreVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resCoreVnet.id
    }
  }
}

resource resKvDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${paramKeyVaultPrivateDnsZoneName}/${resCoreVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resCoreVnet.id
    }
  }
}

// <-- VIRTUAL MACHINE RESOURCES --> //

resource vmCoreNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'vm-core-nsg'
  tags: {
    Owner: 'Sandy'
    Dept: 'Core'
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

resource nicVMCore 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: 'nic-vm'
  location: paramlocation
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: resVMSubnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.20.1.20'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}

resource resVMSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'vmSubnet'
  parent: resCoreVnet
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'vm1core001'
  tags: {
    Owner: 'Sandy'
    Dept: 'Core'
  }
  location: paramlocation
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2S_v3'
    }
    osProfile: {
      computerName: 'vmcore'
      adminUsername: VMusername
      adminPassword: VMpassword
      allowExtensionOperations: true
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
      }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicVMCore.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageUri
      }
    }
  }
}

// <-- VM INSIGHTS --> //

resource daExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name: DaExtensionName
  parent: windowsVM
  location: paramlocation
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: DaExtensionType
    typeHandlerVersion: DaExtensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: true
    }
  }
}

resource amaExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  name: 'AzureMonitorWindowsAgent'
  parent: windowsVM
  location: paramlocation
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: paramWorkspaceId
      azureResourceId: windowsVM.id
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(paramWorkspaceId, '2022-10-01').primarySharedKey
    }
  }
}

// Anti Malware Extension

resource resAntiMalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: windowsVM
  name: 'AntiMalwareExtension'
  location: paramlocation
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: 'true'
    }
  }
}

// <-- AZURE DISK ENCRYPTION --> //

resource DiskEncryption 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: 'AzureDiskEncryption'
  parent: windowsVM
  location: paramlocation
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'AzureDiskEncryption'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '1.0'
    settings: {
      EncryptionOperation: 'EnableEncryption'
      KeyVaultURL: reskeyVaultCore.properties.vaultUri
      KeyVaultResourceId: reskeyVaultCore.id
      VolumeType: 'All'
      ResizeOSDisk: false
    }
  }
}

// <-- KEY VAULT RESOURCES --> //

resource reskeyVaultCore 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: 'kv-encrypt-core-${randNumb}'
  tags: {
    Owner: 'Sandy'
    Dept: 'Core'
  }
  location: paramlocation
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: keyVaultCoreObjectId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
        }
      }
    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource kvCoreNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'kv-core-nsg'
  tags: {
    Owner: 'Sandy'
    Dept: 'Core'
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

resource resKVSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'kVSubnet'
  parent: resCoreVnet
}

resource resKVPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: paramKeyVaultEndpointName
  tags: {
    Owner: 'Sandy'
    Dept: 'Core'
  }
  location: paramlocation
  properties: {
    subnet: {
      id: resKVSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: paramKeyVaultEndpointName
        properties: {
          privateLinkServiceId: reskeyVaultCore.id
          groupIds: [
            'vault'
          ]
          }
        }
    ]
  }
}

resource resKVpvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: resKVPrivateEndpoint
  name: 'mykvdnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'kvconfig'
        properties: {
          privateDnsZoneId: paramKeyVaultPrivateDnsZoneId
        }
      }
    ]
  }
}

// <-- OUTPUTS --> //

output outVnetId string = resCoreVnet.id
output outVnetName string = resCoreVnet.name
output outVmId string = windowsVM.id
output outVmName string = windowsVM.name
