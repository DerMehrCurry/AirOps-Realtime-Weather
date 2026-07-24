AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Version = '0.3.0'
AirOpsWeather.Events = {
    requestSync = 'airops_weather:server:requestSync',
    syncState = 'airops_weather:client:syncState',
    weatherChanged = 'airops_weather:weatherChanged'
}

function AirOpsWeather.Debug(message, ...)
    if not Config.General.debug then return end
    if select('#', ...) > 0 then message = string.format(message, ...) end
    print(('[AirOps Weather][DEBUG] %s'):format(message))
end

function AirOpsWeather.Info(message, ...)
    if select('#', ...) > 0 then message = string.format(message, ...) end
    print(('[AirOps Weather] %s'):format(message))
end

function AirOpsWeather.Warn(message, ...)
    if select('#', ...) > 0 then message = string.format(message, ...) end
    print(('[AirOps Weather][WARN] %s'):format(message))
end
