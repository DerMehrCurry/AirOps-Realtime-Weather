# Commit changes – v0.7.2.2

## Recommended commit

```text
fix(startup): initialize provider registry before dependent modules
```

## Commit body

```text
- load server/providers/base.lua before validation and provider implementations
- fix nil AirOpsWeather.Providers during Open-Meteo registration
- fix resulting nil AirOpsWeather.Validation startup error
- keep existing configuration, exports and SDK compatibility
- bump version to v0.7.2.2
```

## Git tag

```text
v0.7.2.2
```

## GitHub release title

```text
AirOps Realtime Weather Community v0.7.2.2
```
