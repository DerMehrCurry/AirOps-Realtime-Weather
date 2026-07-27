# Self-test

Run the release-candidate self-test from the server console:

```text
airops_weather_selftest
```

Or use the export:

```lua
local report = exports['airops_weather']:RunSelfTest()
```

Checks include:

- configuration validation
- active provider
- default zone
- SDK v1 registration
- JSON schema
- integration bus
- diagnostics availability
