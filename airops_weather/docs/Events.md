# Integration Events

Specific FiveM events remain available. The beta additionally emits the generic:

```text
airops_weather:integrationEvent
```

Its payload contains:

```lua
{
    event = 'weatherChanged',
    payload = {},
    metadata = {},
    timestamp = 0,
    resourceVersion = '0.7.0-beta',
    apiVersion = 1
}
```
