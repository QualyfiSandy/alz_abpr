param pVMName string
param pDCREndpointId string
param pDCRId string

resource resVM 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: pVMName
}

resource resDCRAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'configurationAccessEndpoint'
  properties: {
    dataCollectionEndpointId: pDCREndpointId
    dataCollectionRuleId: pDCRId
  }
  scope: resVM
}
