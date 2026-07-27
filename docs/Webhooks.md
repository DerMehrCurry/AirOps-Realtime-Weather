# Discord Webhooks

Webhooks are disabled by default.

```lua
Config.Webhooks.enabled = true
Config.Webhooks.url = 'YOUR_DISCORD_WEBHOOK_URL'
```

Supported automatic notifications:

- resource startup and shutdown
- provider failure and recovery
- severe weather warnings
- orange and red flight conditions

Messages are queued, rate limited and retried with exponential backoff.
