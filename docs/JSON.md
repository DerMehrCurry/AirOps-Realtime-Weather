# JSON Export

```lua
local payload = exports['airops_weather']:GetJSON()
local document = exports['airops_weather']:GetJSONDocument()
local schema = exports['airops_weather']:GetJSONSchema()
```

The document contains resource, API and SDK versions, provider, zone,
timestamp, weather profile, forecast, warnings, flight conditions and optional
health and diagnostics data.
