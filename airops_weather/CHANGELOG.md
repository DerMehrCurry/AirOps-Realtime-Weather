# Changelog

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
