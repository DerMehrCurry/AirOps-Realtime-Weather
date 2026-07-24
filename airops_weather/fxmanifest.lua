fx_version 'cerulean'
game 'gta5'

author 'AirOps Development'
description 'Core-independent real-time weather and clock synchronization for FiveM.'
version '0.7.0-beta'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/weather_mapping.lua'
}

server_scripts {
    'server/logging.lua',
    'server/validation.lua',
    'server/metrics.lua',
    'server/cache.lua',
    'server/weather_engine.lua',
    'server/timeline.lua',
    'server/integrations/manager.lua',
    'server/integrations/events.lua',
    'server/integrations/metrics.lua',
    'server/integrations/natural_disasters.lua',
    'server/override.lua',
    'server/providers/base.lua',
    'server/providers/openmeteo.lua',
    'server/providers/mock.lua',
    'server/scheduler.lua',
    'server/api.lua',
    'server/sdk/v1.lua',
    'server/sdk/main.lua',
    'server/json/schema.lua',
    'server/json/export.lua',
    'server/webhooks/embeds.lua',
    'server/webhooks/queue.lua',
    'server/webhooks/discord.lua',
    'server/diagnostics.lua',
    'server/main.lua'
}

client_scripts {
    'client/time.lua',
    'client/weather.lua',
    'client/api.lua',
    'client/main.lua'
}
