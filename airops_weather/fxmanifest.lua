fx_version 'cerulean'
game 'gta5'

author 'AirOps Development'
description 'Core-independent real-time weather and clock synchronization for FiveM.'
version '0.7.2.6'

lua54 'yes'

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/weather_mapping.lua'
}

server_script 'server/bootstrap.lua'

client_scripts {
    'client/time.lua',
    'client/weather.lua',
    'client/api.lua',
    'client/main.lua'
}
