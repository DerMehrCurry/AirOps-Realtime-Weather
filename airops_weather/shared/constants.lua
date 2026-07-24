AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Version = '0.5.0'
AirOpsWeather.Events = {
    requestSync = 'airops_weather:server:requestSync',
    syncState = 'airops_weather:client:syncState',
    weatherChanged = 'airops_weather:weatherChanged',
    stateChanged = 'airops_weather:stateChanged',
    profileChanged = 'airops_weather:profileChanged',
    forecastChanged = 'airops_weather:forecastChanged',
    overrideStarted = 'airops_weather:overrideStarted',
    overrideEnded = 'airops_weather:overrideEnded',
    warningsChanged = 'airops_weather:warningsChanged'
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
