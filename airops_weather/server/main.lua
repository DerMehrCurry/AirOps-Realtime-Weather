AirOpsWeather = AirOpsWeather or {}
RegisterNetEvent(AirOpsWeather.Events.requestSync,function() AirOpsWeather.BroadcastState(source) end)
AddEventHandler('onResourceStart',function(name) if name~=GetCurrentResourceName() then return end AirOpsWeather.Info('Starting v%s for %s (%.4f, %.4f).',AirOpsWeather.Version,Config.Location.name,Config.Location.latitude,Config.Location.longitude) AirOpsWeather.UpdateWeather() end)
RegisterCommand('airops_weather_update',function(source) if source~=0 and not IsPlayerAceAllowed(source,'airops.weather.update') then return end AirOpsWeather.Info('Manual weather update requested.') AirOpsWeather.UpdateWeather() end,false)
exports('getWeatherData',function() return AirOpsWeather.PublicState() end)
exports('forceWeatherUpdate',function() return AirOpsWeather.UpdateWeather() end)
