fx_version 'cerulean'
game 'gta5'

author 'AirOps Development'
description 'Core-independent real-time weather and clock synchronization for FiveM.'
version '0.1.0'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/weather_mapping.lua'
}

server_scripts {
    'server/cache.lua',
    'server/weather_engine.lua',
    'server/providers/openmeteo.lua',
    'server/scheduler.lua',
    'server/main.lua'
}

client_scripts {
    'client/time.lua',
    'client/weather.lua',
    'client/main.lua'
}
