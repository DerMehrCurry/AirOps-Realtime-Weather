# Changelog

## [0.4.0] - 2026-07-24

### Added

- internal API, broadcast, timeline and weather-change metrics
- provider request watchdog with late-callback protection
- stale-cache health state and warning
- configurable broadcast significance thresholds
- `getPerformanceMetrics` server export
- Natural Disasters resource start/stop handling

### Changed

- suppress unchanged global state broadcasts
- retain a periodic safety heartbeat for long-running clients
- reduce Natural Disasters polling during normal operation
- increase standalone client weather reinforcement interval to 60 seconds
- replace the permanent override-expiry loop with scheduled callbacks
- restore an active manual override after Natural Disasters releases control
- expand `airops_weather_status` with performance and health diagnostics

### Fixed

- prevent delayed provider callbacks from creating duplicate scheduler chains
- immediately return to standalone mode when Natural Disasters stops
- preserve manual weather priority when external disaster control ends

## [0.3.0] - 2026-07-24

### Added

- manual weather overrides through `/airops weather <type> [durationMinutes]`
- manual time overrides through `/airops time <hour> <minute> [durationMinutes]`
- separate realtime restoration for weather, time, or all overrides
- automatic expiration of temporary overrides
- priority handling between Natural Disasters, manual overrides, and realtime data
- `setWeatherOverride`, `setTimeOverride`, `clearOverride`, and `getOverrideState` server exports
- configurable override command, duration limit, permanent overrides, and transition duration
- override state in the public synchronization payload and diagnostics

### Changed

- realtime provider observations and forecast timeline continue updating while overrides are active
- weather candidates are suppressed while a manual weather override owns the baseline
- manual time runs forward at real speed from the configured hour and minute
- README fully updated for installation, commands, ACE permissions, exports, integration, and testing

## [0.2.1] - 2026-07-24

### Added

- deterministic flexible weather timing around hourly forecast reference points
- configurable forecast offset of up to 20 minutes before or after the provider hour
- natural multi-stage transitions such as CLOUDS -> OVERCAST -> RAIN -> THUNDER
- weather-class-specific blend durations
- ordered transition spacing to prevent several weather states firing together

### Changed

- hourly Open-Meteo values are now treated as forecast targets instead of exact switch times
- timeline diagnostics distinguish intermediate transition steps from final targets

## [0.2.0] - 2026-07-24

### Added

- hourly Open-Meteo forecast timeline
- automatic scheduled weather changes without extra API requests
- compression of consecutive identical forecast states
- protection against stale timeline callbacks after forecast refreshes
- optional filtering of short forecast reversals
- `airops_weather_status` diagnostic command
- `getForecastTimeline` server export
- next forecast state in the public synchronization payload

### Changed

- default forecast window increased from 6 to 12 hours
- weather changes now pass through one shared application path

## [0.1.3] - 2026-07-24

### Fixed

- stop the native GTA clock from advancing faster than real time between synchronizations
- remove visible time jumps between real time and approximately five minutes ahead
- update the locally calculated real clock once per second
- release the paused native clock when AirOps stops or relinquishes time control

## [0.1.2] - 2026-07-24

### Fixed

- automatic standalone fallback when `night_natural_disasters` is not installed or not started
- AirOps client weather synchronization now remains active without Natural Disasters
- integration availability is checked dynamically instead of treating configuration as a hard dependency
- automatic switch to compatibility mode when Natural Disasters starts later

## [0.1.1] - 2026-07-24

### Added

- direct compatibility mode for `night_natural_disasters`
- delegated baseline weather through Natural Disasters `SetWeather`
- automatic detection when disaster weather takes control
- external-control events, exports, and test commands
- conflict prevention by disabling AirOps client weather natives in integration mode

### Changed

- Natural Disasters becomes the sole client weather synchronizer when integration is enabled
- AirOps continues updating its real-weather cache while disaster weather is active

## [0.1.0] - 2026-07-24

- initial development build
