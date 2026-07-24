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
