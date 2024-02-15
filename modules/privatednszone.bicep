param paramPrivateDnsZoneName string

// PRIVATE DNS ZONES
resource resPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: paramPrivateDnsZoneName
  location: 'global'
}

output outPrivateDnsZoneId string = resPrivateDnsZone.id
output outPrivateDnsZoneName string = resPrivateDnsZone.name
