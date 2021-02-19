# Example namedLocations.json

### Create a IP range named location
https://docs.microsoft.com/de-de/graph/api/resources/ipnamedlocation?view=graph-rest-1.0
```json
{
    "type": "ipNamedLocation",
    "displayName": "Untrusted IP named location",
    "isTrusted": false,
    "ipRanges": [
        {
            "@odata.type": "#microsoft.graph.iPv4CidrRange",
            "cidrAddress": "12.34.221.11/22"
        },
        {
            "@odata.type": "#microsoft.graph.iPv6CidrRange",
            "cidrAddress": "2001:0:9d38:90d6:0:0:0:0/63"
        }
    ],
    "present": true
}
```

### Create a country named location
https://docs.microsoft.com/de-de/graph/api/resources/countrynamedlocation?view=graph-rest-1.0
```json
{
    "type": "countryNamedLocation",
    "displayName": "Named location with unknown countries and regions",
    "countriesAndRegions": [
        "US",
        "GB"
    ],
    "includeUnknownCountriesAndRegions": true,
    "present": true
}
```

Named location resource type: https://docs.microsoft.com/de-de/graph/api/resources/namedlocation?view=graph-rest-1.0