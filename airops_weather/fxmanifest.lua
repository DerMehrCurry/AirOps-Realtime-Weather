fx_version 'cerulean'
game 'gta5'

author 'AirOps Development'
description 'Core-independent real-time weather and clock synchronization for FiveM.'
version '0.5.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/weather_mapping.lua'
}

server_scripts {
    'server/metrics.lua',
    'server/cache.lua',
    'server/weather_engine.lua',
    'server/timeline.lua',
    'server/integrations/natural_disasters.lua',
    'server/override.lua',
    'server/providers/openmeteo.lua',
    'server/scheduler.lua',
    'server/api.lua',
    'server/main.lua'
}

client_scripts {
    'client/time.lua',
    'client/weather.lua',
    'client/api.lua',
    'client/main.lua'
}
