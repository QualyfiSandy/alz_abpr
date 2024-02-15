param paramlocation string

// ROUTE TABLE
resource resRouteToAfw 'Microsoft.Network/routeTables@2022-01-01' = {
  name: 'route-to-${paramlocation}-hub-fw'
  tags: {
    Owner: 'Sandy'
    Dept: 'Infrastructure'
  }
  location: paramlocation
  properties: {
    routes: [
      {
        name: 'routeToFirewall'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '10.10.3.4'
        }
      }
    ]
  }
}

output outRouteToAfw string = resRouteToAfw.id
