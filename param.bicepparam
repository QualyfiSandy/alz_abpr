using './main.bicep'

param pLocation = 'uksouth'

param pCoreSecKeyVaultName = 'kv-sec-core-sandy'
param pHubVnetName = 'hub-${pLocation}-001'
param pCoreVnetName = 'core-${pLocation}-001'
param pDevVnetName = 'dev-${pLocation}-001'
param pProdVnetName = 'prod-${pLocation}-001'
param pGatewaySubnetName = 'GatewaySubnet'
param pAppGwSubnetName = 'AppGwSubnet'
param pAzureFirewallSubnetName = 'AzureFirewallSubnet'
param pBastionSubnetName = 'AzureBastionSubnet'
param pVMSubnetName = 'VMSubnet'
param pKVSubnetName = 'KVSubnet'
param pAppSubnetName = 'AppSubnet'
param pSqlSubnetName = 'SqlSubnet'
param pStSubnetName = 'StSubnet'
param pRouteTableName = 'route-to-${pLocation}-hub-fw'
param pBastionName = 'bas-hub-${pLocation}-001'
param pBastionPIPName = 'bas-pip-${pLocation}'
param pVPNGatewayName = 'vgw-hub-${pLocation}-001'
param pVPNGatewayPIPName = 'vgw-pip-${pLocation}'
param pVPNGatewaySkuName = 'VpnGw2'
param pVPNGatewayType = 'Vpn'
param pVMName = 'vm1core001'
param pVMComputerName = 'CoreComputer'
param pVMSize = 'Standard_D2S_v3'
param pCoreEncryptionKeyVaultName = 'kv-encrypt-core-'
param pRSVName = 'rsv-core-${pLocation}-001'
param pDevAppServicePlanName = 'asp-dev-${pLocation}-001-12345'
param pAppServicePlanSku = 'S1'
param pAppServicePlanTier = 'Standard'
param pProdAppServicePlanName = 'asp-prod-${pLocation}-001-12345'
param pDevAppServiceName = 'as-dev-${pLocation}-001-12345'
param pProdAppServiceName = 'as-prod-${pLocation}-001-12345'
param pLogAnalyticsWorkspaceName = 'log-core-${pLocation}-001'
param pProdSqlServerName = 'sql-prod-${pLocation}-001-'
param pDevSqlServerName = 'sql-dev-${pLocation}-001-'
param pProdSqlDatabaseName = 'sqldb-prod-${pLocation}-001'
param pDevSqlDatabaseName = 'sqldb-dev-${pLocation}-001'
param pProdStName = 'stprod001010690'
param pDevStName = 'stdev001010690'
param pStKind = 'StorageV2'
param pStSkuName = 'Standard_LRS'
param pAppGatewayName = 'agw-hub-${pLocation}-001'
param pAppGatewayPIPName = 'agw-pip-${pLocation}'
param pAzureFirewallName = 'afw-hub-${pLocation}-001'
param pAzureFirewallPIPName = 'afw-pip-${pLocation}'
param pAzureFirewallPolicyName = 'afw-hub-policy'

param pHubVnetAddressPrefix = '10.10'
param pCoreVnetAddressPrefix = '10.20'
param pDevVnetAddressPrefix = '10.30'
param pProdVnetAddressPrefix = '10.31'
param pNICVMIP = '10.20.1.20'
