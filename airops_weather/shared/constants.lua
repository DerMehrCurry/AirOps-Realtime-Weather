AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Version = '0.7.2.3'
AirOpsWeather.APIVersion = 1
AirOpsWeather.DefaultZone = 'default'
AirOpsWeather.Events = {
    requestSync = 'airops_weather:server:requestSync',
    syncState = 'airops_weather:client:syncState',
    weatherChanged = 'airops_weather:weatherChanged',
    stateChanged = 'airops_weather:stateChanged',
    profileChanged = 'airops_weather:profileChanged',
    forecastChanged = 'airops_weather:forecastChanged',
    overrideStarted = 'airops_weather:overrideStarted',
    overrideEnded = 'airops_weather:overrideEnded',
    warningsChanged = 'airops_weather:warningsChanged',
    providerUnavailable = 'airops_weather:providerUnavailable',
    providerRecovered = 'airops_weather:providerRecovered',
    healthChanged = 'airops_weather:healthChanged',
    integrationEvent = 'airops_weather:integrationEvent',
    jsonUpdated = 'airops_weather:jsonUpdated',
    warningAdded = 'airops_weather:warningAdded',
    warningRemoved = 'airops_weather:warningRemoved',
    providerFailed = 'airops_weather:providerFailed',
    zoneRegistered = 'airops_weather:zoneRegistered',
    zoneChanged = 'airops_weather:zoneChanged',
    selfTestCompleted = 'airops_weather:selfTestCompleted'
}

local function fallbackLog(level, message, ...)
    if select('#', ...) > 0 then
        message = string.format(message, ...)
    end

    print(('[AirOps Weather][%s] %s'):format(level, message))
end

function AirOpsWeather.Trace(message, ...)
    if AirOpsWeather.Log then
        return AirOpsWeather.Log('TRACE', message, ...)
    end
end

function AirOpsWeather.Debug(message, ...)
    if AirOpsWeather.Log then
        return AirOpsWeather.Log('DEBUG', message, ...)
    end

    if Config.General.debug then
        fallbackLog('DEBUG', message, ...)
    end
end

function AirOpsWeather.Info(message, ...)
    if AirOpsWeather.Log then
        return AirOpsWeather.Log('INFO', message, ...)
    end

    fallbackLog('INFO', message, ...)
end

function AirOpsWeather.Warn(message, ...)
    if AirOpsWeather.Log then
        return AirOpsWeather.Log('WARN', message, ...)
    end

    fallbackLog('WARN', message, ...)
end

function AirOpsWeather.Error(message, ...)
    if AirOpsWeather.Log then
        return AirOpsWeather.Log('ERROR', message, ...)
    end

    fallbackLog('ERROR', message, ...)
end
