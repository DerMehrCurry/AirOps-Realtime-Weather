# Public API v1

## Weather

```lua
GetWeather(zone?)
GetTime(zone?)
GetState(zone?)
GetForecast(hours?, zone?)
GetFlightConditions()
GetWarnings()
```

## SDK

```lua
GetSDK(version?)
GetAPIVersion()
GetSDKVersions()
```

## JSON

```lua
GetJSON(zone?)
GetJSONPretty(zone?)
GetJSONDocument(zone?)
GetJSONSchema()
```

## Providers

```lua
GetRegisteredProviders()
```

## Zones

```lua
GetWeatherZones()
GetWeatherZone(name)
RegisterWeatherZone(name, definition)
GetZoneState(name)
GetZoneStates()
```

## Integrations

```lua
RegisterIntegrationListener(eventName, callback)
RemoveIntegrationListener(listenerId)
GetIntegrationHistory()
GetIntegrationMetrics()
```

## Diagnostics

```lua
GetHealth()
GetDiagnostics()
GetIntegrations()
GetForecastDiagnostics()
ValidateConfiguration()
RunSelfTest()
```
