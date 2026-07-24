local AirOps = exports['airops_weather']:GetSDK(1)

AirOps:Subscribe('warningAdded', function(warning)
    TriggerEvent('dispatch:addWeatherAlert', {
        title = warning.message or warning.code,
        severity = warning.severity,
        code = warning.code
    })
end)
