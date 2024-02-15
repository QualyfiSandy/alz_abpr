param paramlocation string = resourceGroup().location

param workspaceResourceId string
param paramStPrivateDnsZoneName string
param SqlDbPrivateDnsZoneName string
param privateAspDnsZoneName string
param paramKeyVaultPrivateDnsZoneName string



// <-- HUB VIRTUAL NETWORK --> //
resource resHubVnet 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: 'vnet-hub-${paramlocation}-001'
  location: paramlocation
  tags: {
    Owner: 'Sandy'
    Dept: 'Infrastructure'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
      {
        name: 'AppgwSubnet'
        properties: {
          addressPrefix: '10.10.2.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.10.3.0/24'
        }
      }
      {
        name: 'azureBastionSubnet'
        properties: {
          addressPrefix: '10.10.4.0/24'
        }
      }
    ]
  }
}

resource resAgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'AppgwSubnet'
  parent: resHubVnet
}

resource resStDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${paramStPrivateDnsZoneName}/${resHubVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resHubVnet.id
    }
  }
}

resource resSqlDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${SqlDbPrivateDnsZoneName}/${resHubVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resHubVnet.id
    }
  }
}

resource resAspDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateAspDnsZoneName}/${resHubVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resHubVnet.id
    }
  }
}

resource resKvDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${paramKeyVaultPrivateDnsZoneName}/${resHubVnet.name}-spokelink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resHubVnet.id
    }
  }
}

// <-- BASTION RESOURCES --> //

resource pipAzureBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'pip-ab-${paramlocation}'
  tags: {
    Owner: 'Sandy'
    Dept: 'Hub'
  }
  location: paramlocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'azureBastionSubnet'
  parent: resHubVnet
}

resource azureBastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: 'bas-hub-${paramlocation}-001'
  tags: {
    Owner: 'Sandy'
    Dept: 'Hub'
  }
  location: paramlocation
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'hub-subnet'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: pipAzureBastion.id
          }
        }
      }
    ]
  }
}

// <-- AZURE FIREWALL RESOURCES --> //

resource pipAzureFirewall 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: 'pip-afw-${paramlocation}'
  tags: {
    Owner: 'Sandy'
    Dept: 'Hub'
  }
  location: paramlocation
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPAddressVersion: 'IPv4'
  }
}

resource firewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  name: 'azureFirewallSubnet'
  parent: resHubVnet
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2021-05-01' = {
  name: 'afw-hub-policy'
  tags: {
    Owner: 'Sandy'
    Dept: 'Hub'
  }
  location: paramlocation
  properties: {
    sku: {
      tier: 'Standard'
    }
    dnsSettings: {
      enableProxy: true
    }
    threatIntelMode: 'Alert'
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2021-05-01' = {
  name: 'afw-hub-${paramlocation}-001'
  tags: {
    Owner: 'Sandy'
    Dept: 'Hub'
  }
  location: paramlocation
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }    
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: pipAzureFirewall.name
        properties: {
          subnet: {
            id: firewallSubnet.id
          }
          publicIPAddress: {
            id: pipAzureFirewall.id
          }
        }
      }
    ]
  }
}

resource networkRuleCollectionGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2022-01-01' = {
  parent: firewallPolicy
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'AllowAll'
        priority: 100
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'time-windows'
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
}

resource fwHub_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-hub-la'
  scope: azureFirewall
  properties: {
    workspaceId: workspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// <-- VPN HUB GATEWAY --> //

// resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
//   name: 'GatewaySubnet'
//   parent: resHubVnet
// }

// resource pipHubGateway 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
//   name: 'pip-vgw-${paramlocation}'
//   location: paramlocation
//   sku: {
//     name: 'Standard'
//   }
//   properties: {
//     publicIPAllocationMethod: 'Static'
//     idleTimeoutInMinutes: 4
//     publicIPAddressVersion: 'IPv4'
//   }
// }

// resource vgwHub 'Microsoft.Network/virtualNetworkGateways@2022-01-01' = {
//   name: 'vgw-hub-${paramlocation}-001'
//   location: paramlocation
//   properties: {
//     sku: {
//       name: 'VpnGw1'
//       tier: 'VpnGw1'
//     }
//     gatewayType: 'Vpn'
//     vpnType: 'RouteBased'
//     vpnGatewayGeneration: 'Generation1'
//     ipConfigurations: [
//       {
//         name: 'default'
//         properties: {
//           privateIPAllocationMethod: 'Dynamic'
//           publicIPAddress: {
//             id: pipHubGateway.id
//           }
//           subnet: {
//             id: gatewaySubnet.id
//           }
//         }
//       }
//     ]
//   }
// }

// <-- OUTPUTS --> //

output outVnetId string = resHubVnet.id
output outVnetName string = resHubVnet.name

output outafwId string = pipAzureFirewall.id
output outAgwSubnetId string = resAgwSubnet.id
