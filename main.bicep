param paramlocation string = resourceGroup().location
param paramLogAnalyticsName string = 'log-core-${paramlocation}-001-123'
param paramAppInsightsName string = 'appinsights-001'

param keyVaultObjectId string
param keyVaultName string
param randNumb string = '16022023'

var varSqlEndpoint = 'privatelink${environment().suffixes.sqlServerHostname}'
var varKeyVaultEndpoint = 'privatelink${environment().suffixes.keyvaultDns}'
var varStEndpoint = 'privatelink.blob.${environment().suffixes.storage}'

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
      paramAgwSubnetId: modHub.outputs.outAgwSubnetId
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

// ROUTE TABLE MODULE
module modRoutes 'modules/routetable.bicep' = {
  name: 'routetable'
  params: {
    paramlocation: paramlocation
  }
}

// HUB MODULE
module modHub 'modules/hub.bicep' = {
  name: 'hub-${paramlocation}-001'
  params: {
    paramlocation: paramlocation
    workspaceResourceId: modLogAnalytics.outputs.logAnalyticsId
    paramKeyVaultPrivateDnsZoneName: modPrivateDnsZoneKeyVault.outputs.outPrivateDnsZoneName
    paramStPrivateDnsZoneName: modPrivateDnsZoneSt.outputs.outPrivateDnsZoneName
    privateAspDnsZoneName: modPrivateDnsZoneAsp.outputs.outPrivateDnsZoneName
    SqlDbPrivateDnsZoneName: modPrivateDnsZoneSQL.outputs.outPrivateDnsZoneName
  }
}

// CORE MODULE
module modCore 'modules/core.bicep' = {
  name: 'core-${paramlocation}-001'
  params: {
    paramlocation: paramlocation
    VMusername: resKeyVault.getSecret('VMusername')
    VMpassword: resKeyVault.getSecret('VMpassword')
    resRouteTable: modRoutes.outputs.outRouteToAfw
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
    resRouteTable: modRoutes.outputs.outRouteToAfw
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
    paramSqlPassword: resKeyVault.getSecret('SQLdevpassword')
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
    resRouteTable: modRoutes.outputs.outRouteToAfw
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
    paramSqlPassword: resKeyVault.getSecret('SQLprodpassword')
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

// PEERING MODULES

module modHubToCorePeering 'modules/peering.bicep' = {
  name: 'hub-to-core-peering'
  params: {
    parSourceVnetName: modHub.outputs.outVnetName
    parTargetVnetName: modCore.outputs.outVnetName
    parTargetVnetId: modCore.outputs.outVnetId
  }
}

module modCoretoHubPeering 'modules/peering.bicep' = {
  name: 'core-to-hub-peering'
  params: {
    parSourceVnetName: modCore.outputs.outVnetName
    parTargetVnetName: modHub.outputs.outVnetName
    parTargetVnetId: modHub.outputs.outVnetId
  }
}

module modHubtoProdPeering 'modules/peering.bicep' = {
  name: 'hub-to-prod-peering'
  params: {
    parSourceVnetName: modHub.outputs.outVnetName
    parTargetVnetName: modProd.outputs.outVnetName
    parTargetVnetId: modProd.outputs.outVnetId
  }
}

module modProdtoHubPeering 'modules/peering.bicep' = {
  name: 'prod-to-hub-peering'
  params: {
    parSourceVnetName: modProd.outputs.outVnetName
    parTargetVnetName: modHub.outputs.outVnetName
    parTargetVnetId: modHub.outputs.outVnetId
  }
}
