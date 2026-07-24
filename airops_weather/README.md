# AirOps Realtime Weather – Community Edition

Core-independent real-time weather and clock synchronization for FiveM.

> This resource is free. If you paid a third party for the Community Edition, you were misled.

## Version 0.1.0

First functional development build with:

- Open-Meteo weather data
- real local time and automatic daylight-saving offset
- centralized server cache
- adaptive provider polling
- smooth GTA weather transitions
- wind speed and direction
- retry backoff
- framework-independent synchronization

## Installation

1. Copy `airops_weather` into your server resources.
2. Edit `config.lua`.
3. Add `ensure airops_weather` to `server.cfg`.

Optional ACE permission:

```cfg
add_ace group.admin airops.weather.update allow
```

Manual command: `airops_weather_update`

## Known limitations

- Forecast data is cached but not yet converted into a complete weather timeline.
- Only Open-Meteo is included.
- Other time/weather scripts can conflict with this resource.

Weather data by Open-Meteo. See `LICENSE`.

## Natural Disasters compatibility

Version 0.1.1 can delegate all client weather synchronization to
`night_natural_disasters`. This prevents both resources from repeatedly
setting different weather states.

Start order:

```cfg
ensure night_natural_disasters
ensure airops_weather
```

Keep the integration enabled in `config.lua`:

```lua
Config.Integrations.naturalDisasters.enabled = true
Config.Integrations.naturalDisasters.delegateWeather = true
```

AirOps sends its real baseline weather through the Natural Disasters
`SetWeather` server export. If Natural Disasters changes to a different weather
stage, AirOps recognizes external ownership and stops sending baseline changes.
The real weather cache continues updating in the background.

Test commands:

```text
airops_weather_nd_lock
airops_weather_nd_release
```

Optional ACE permission:

```cfg
add_ace group.admin airops.weather.integration allow
```

Server export for an explicit integration hook:

```lua
exports['airops_weather']:setExternalWeatherControl(true, 'natural_disasters')
exports['airops_weather']:setExternalWeatherControl(false)
```

Equivalent server event:

```lua
TriggerEvent('airops_weather:server:setExternalWeatherControl', true, 'natural_disasters')
TriggerEvent('airops_weather:server:setExternalWeatherControl', false)
```
