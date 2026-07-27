# AirOps Integration SDK v1

```lua
local AirOps = exports['airops_weather']:GetSDK(1)

local weather = AirOps:GetWeather()
local forecast = AirOps:GetForecast({ hours = 6 })
local jsonPayload = AirOps:GetJSON()
```

## Push events

```lua
local listenerId = AirOps:Subscribe('warningAdded', function(warning)
    print(warning.code, warning.message)
end)

AirOps:Unsubscribe(listenerId)
```

Available integration event names include:

- `weatherChanged`
- `forecastUpdated`
- `warningAdded`
- `warningRemoved`
- `warningsUpdated`
- `providerFailed`
- `providerRecovered`
- `healthChanged`
- `jsonUpdated`


## Zone discovery

```lua
local zones = AirOps:GetZones()
local defaultZone = AirOps:GetZone('default')
local state = AirOps:GetZoneState('default')
```

## Release-candidate compatibility promise

SDK v1 is frozen for the remainder of the v0.7 release cycle. Breaking SDK v1
changes are deferred to a future major API version.
