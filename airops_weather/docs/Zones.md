# Weather Zones

v0.7.0-rc stabilizes the zone-aware API.

The resource still uses one shared weather state by default:

```lua
Config.Zones.sharedState = true
```

Configured zones:

```lua
Config.Zones.definitions = {
    default = {
        label = 'Global',
        enabled = true,
        metadata = {
            type = 'global'
        }
    }
}
```

Additional zones can already be registered for integrations:

```lua
exports['airops_weather']:RegisterWeatherZone('airport', {
    label = 'Airport',
    enabled = true,
    metadata = {
        type = 'aviation'
    }
})
```

Available exports:

```lua
GetWeatherZones()
GetWeatherZone(name)
RegisterWeatherZone(name, definition)
GetZoneState(name)
GetZoneStates()
```

Registering a zone does not create separate live weather yet. Independent
regional weather remains a post-v1 feature.
