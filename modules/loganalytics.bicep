param paramlocation string
param paramLogAnalyticsName string

// LOG ANALYTICS
resource resLogAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: paramLogAnalyticsName
  location: paramlocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: false
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}

resource logAnalyticsWorkspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: resLogAnalytics
  name: 'diagnosticSettings'
  properties: {
    workspaceId: resLogAnalytics.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
}

resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  location: paramlocation
  name: 'VMInsights(${split(resLogAnalytics.id, '/')[8]})'
  properties: {
    workspaceResourceId: resLogAnalytics.id
  }
  plan: {
    name: 'VMInsights(${split(resLogAnalytics.id, '/')[8]})'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}

resource MyDCR 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'MyDcr'
  location: paramlocation
  kind: 'Windows'
  properties: {
    dataSources: {
      performanceCounters: [
        {
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
                                '\\Processor Information(_Total)\\% Processor Time'
                                '\\Processor Information(_Total)\\% Privileged Time'
                                '\\Processor Information(_Total)\\% User Time'
                                '\\Processor Information(_Total)\\Processor Frequency'
                                '\\System\\Processes'
                                '\\Process(_Total)\\Thread Count'
                                '\\Process(_Total)\\Handle Count'
                                '\\System\\System Up Time'
                                '\\System\\Context Switches/sec'
                                '\\System\\Processor Queue Length'
                                '\\Memory\\% Committed Bytes In Use'
                                '\\Memory\\Available Bytes'
                                '\\Memory\\Committed Bytes'
                                '\\Memory\\Cache Bytes'
                                '\\Memory\\Pool Paged Bytes'
                                '\\Memory\\Pool Nonpaged Bytes'
                                '\\Memory\\Pages/sec'
                                '\\Memory\\Page Faults/sec'
                                '\\Process(_Total)\\Working Set'
                                '\\Process(_Total)\\Working Set - Private'
                                '\\LogicalDisk(_Total)\\% Disk Time'
                                '\\LogicalDisk(_Total)\\% Disk Read Time'
                                '\\LogicalDisk(_Total)\\% Disk Write Time'
                                '\\LogicalDisk(_Total)\\% Idle Time'
                                '\\LogicalDisk(_Total)\\Disk Bytes/sec'
                                '\\LogicalDisk(_Total)\\Disk Read Bytes/sec'
                                '\\LogicalDisk(_Total)\\Disk Write Bytes/sec'
                                '\\LogicalDisk(_Total)\\Disk Transfers/sec'
                                '\\LogicalDisk(_Total)\\Disk Reads/sec'
                                '\\LogicalDisk(_Total)\\Disk Writes/sec'
                                '\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer'
                                '\\LogicalDisk(_Total)\\Avg. Disk sec/Read'
                                '\\LogicalDisk(_Total)\\Avg. Disk sec/Write'
                                '\\LogicalDisk(_Total)\\Avg. Disk Queue Length'
                                '\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length'
                                '\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length'
                                '\\LogicalDisk(_Total)\\% Free Space'
                                '\\LogicalDisk(_Total)\\Free Megabytes'
                                '\\Network Interface(*)\\Bytes Total/sec'
                                '\\Network Interface(*)\\Bytes Sent/sec'
                                '\\Network Interface(*)\\Bytes Received/sec'
                                '\\Network Interface(*)\\Packets/sec'
                                '\\Network Interface(*)\\Packets Sent/sec'
                                '\\Network Interface(*)\\Packets Received/sec'
                                '\\Network Interface(*)\\Packets Outbound Errors'
                                '\\Network Interface(*)\\Packets Received Errors'
          ]
          name: 'perfCounterDataSource60'
        }
      ]
    }
    destinations: {
      azureMonitorMetrics: {
        name: 'azureMonitorMetrics-default'
      }
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'azureMonitorMetrics-default'
        ]
      }
    ]
  }
}

resource windowsEventsSystemDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: resLogAnalytics
  name: 'WindowsEventsSystem'
  kind: 'WindowsEvent'
  properties: {
    eventLogName: 'System'
    eventTypes: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
    ]
  }
}

resource WindowsEventApplicationDataSource 'Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01' = {
  parent: resLogAnalytics
  name: 'WindowsEventsApplication'
  kind: 'WindowsEvent'
  properties: {
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
  }
}

output logAnalyticsId string = resLogAnalytics.id
output logAnalticsNames string = resLogAnalytics.name
