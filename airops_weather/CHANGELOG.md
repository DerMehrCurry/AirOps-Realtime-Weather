# Changelog

## [0.7.1] - 2026-07-24

### Fixed

- prevent volatile timestamps from triggering continuous API and JSON change events
- implement genuinely formatted output for `GetJSONPretty()`
- remove duplicate `zoneRegistered` and `zoneChanged` integration publications
- preserve actual Lua errors in self-test reports
- normalize weather warning severities to `INFO`, `YELLOW`, `ORANGE`, and `RED`
- send shutdown webhooks directly instead of placing them in a queue that cannot finish after resource stop
- update remaining release-candidate documentation references

### Compatibility

- no exports removed
- no SDK v1 methods removed
- existing default-zone behavior preserved

## [0.7.1] - 2026-07-24

### Added

- formal weather-zone registry and discovery exports
- shared-state zone compatibility layer
- zone registration and zone change integration events
- SDK v1 zone discovery helpers
- release-candidate self-test and console command
- configuration validation for zones and webhooks
- complete public API reference
- zone and self-test documentation
- migration guides for alpha, beta and release candidate
- dispatch, phone, scoreboard and website bridge examples

### Changed

- version bumped to `0.7.1`
- zone resolution now uses the central zone registry
- JSON documents include registered zone metadata
- SDK v1 surface is frozen for the remainder of v0.7
- README documents the release-candidate compatibility policy

### Compatibility

- no existing exports were removed
- no SDK v1 methods were removed
- calls without an explicit zone still use `default`
- all zones continue to share the global weather state by default
- independent regional weather is intentionally deferred

## [0.7.0-beta] - 2026-07-24

### Added

- integration event bus with listener registration and event history
- generic `airops_weather:integrationEvent`
- standardized JSON document, payload and schema exports
- SDK JSON methods and push listener methods
- Discord webhook notifications
- webhook queue, rate limiting and exponential retry logic
- integration metrics and diagnostics data
- warning added and warning removed events
- provider failed compatibility event
- developer documentation for SDK, JSON, events, providers and webhooks
- simple integration and HEMS example resources
- AirOps Development logo and banner assets

### Changed

- version bumped to `0.7.0-beta`
- diagnostics now include integration metrics
- SDK v1 exposes integration and JSON helpers
- README uses the AirOps Development branding
- existing AirOps events are bridged into the integration event bus

### Compatibility

- all public exports from v0.7.0-alpha remain available
- existing server events remain available
- webhooks are disabled by default
- integrations can continue polling or migrate to push listeners incrementally

## [0.7.0-alpha] - 2026-07-24

### Added

- versioned Integration SDK with `GetSDK(version)`
- SDK v1 metadata and discovery exports
- provider registry and common provider interface
- `GetRegisteredProviders` export
- deterministic mock provider for development and testing
- optional `default` zone parameter across the public API
- zone metadata in weather, time and state responses
- `Config.SDK` and `Config.MockProvider`

### Changed

- scheduler now fetches data through the provider registry
- Open-Meteo now implements the common provider contract
- provider validation checks registered providers instead of hard-coding Open-Meteo
- diagnostics expose active and registered providers
- public exports accept optional zone arguments without breaking old calls
- version bumped to `0.7.0-alpha`

### Compatibility

- all v0.5.0 and v0.6.0 public exports remain available
- lowercase export aliases remain available
- SDK v1 wraps the existing API instead of replacing it
- global weather behavior remains unchanged; only the `default` zone exists

## [0.6.0] - 2026-07-24

### Added

- health states `HEALTHY`, `DEGRADED` and `UNHEALTHY`
- `GetHealth`, `GetDiagnostics`, `GetIntegrations` and `GetForecastDiagnostics` exports
- automatic startup configuration validation
- `ValidateConfiguration` export
- configurable logging levels `ERROR`, `WARN`, `INFO`, `DEBUG` and `TRACE`
- repeated-log suppression and summary messages
- provider unavailable and provider recovered events
- health change event
- detailed forecast diagnostics
- standalone admin and console diagnostic commands
- safe configuration snapshot in diagnostics

### Changed

- provider startup is blocked when configuration validation has critical errors
- status output now includes overall health and configuration validity
- `/airops` supports health, forecast, warnings, metrics and integrations
- README version references and roadmap were reviewed and corrected

### Fixed

- corrected the outdated `0.3.0` development-version note at the end of README
- provider recovery is explicitly detected after request failures
- repeated identical provider errors no longer flood the console

## [0.5.0] - 2026-07-24

### Added

- versioned public server API
- `GetWeather`, `GetTime`, `GetState`, `GetForecast`, `GetFlightConditions` and `GetWarnings` exports
- lowercase compatibility aliases for all new exports
- client-side cached state, weather and time exports
- standardized weather profile with intensity, source and transition data
- derived road condition and recommended speed factor
- configurable flight-condition categories
- configurable weather warnings
- state, profile, forecast, warning and override events
- humidity and surface pressure provider fields
- meteorological values on forecast timeline entries

### Changed

- legacy `getWeatherData` now returns the complete public API state
- legacy `getForecastTimeline` uses the standardized forecast API
- client sync state now contains precipitation, cloud cover, visibility, humidity and pressure
- README expanded with API contracts and integration examples

### Compatibility

- existing v0.4.0 commands, overrides, Natural Disasters support and exports remain available
- no framework dependency was introduced

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
