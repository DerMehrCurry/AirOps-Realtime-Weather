AirOpsWeather = AirOpsWeather or {}

local previousWarnings = {}

local function warningKey(warning)
    return tostring(warning.code or warning.message or 'UNKNOWN')
end

local function publish(eventName, payload, sourceEvent)
    AirOpsWeather.Integrations.Publish(
        eventName,
        payload,
        { sourceEvent = sourceEvent }
    )
end

AddEventHandler(AirOpsWeather.Events.weatherChanged, function(previous, current, reason)
    publish('weatherChanged', {
        previous = previous,
        current = current,
        reason = reason
    }, AirOpsWeather.Events.weatherChanged)
end)

AddEventHandler(AirOpsWeather.Events.forecastChanged, function(forecast)
    publish('forecastUpdated', forecast, AirOpsWeather.Events.forecastChanged)
end)

AddEventHandler(AirOpsWeather.Events.providerUnavailable, function(data)
    TriggerEvent(AirOpsWeather.Events.providerFailed, data)
    publish('providerFailed', data, AirOpsWeather.Events.providerUnavailable)
end)

AddEventHandler(AirOpsWeather.Events.providerRecovered, function(data)
    publish('providerRecovered', data, AirOpsWeather.Events.providerRecovered)
end)

AddEventHandler(AirOpsWeather.Events.healthChanged, function(data)
    publish('healthChanged', data, AirOpsWeather.Events.healthChanged)
end)

AddEventHandler(AirOpsWeather.Events.warningsChanged, function(warnings)
    local current = {}

    for _, warning in ipairs(warnings or {}) do
        local key = warningKey(warning)
        current[key] = warning

        if not previousWarnings[key] then
            TriggerEvent(AirOpsWeather.Events.warningAdded, warning)
            publish('warningAdded', warning, AirOpsWeather.Events.warningsChanged)
        end
    end

    for key, warning in pairs(previousWarnings) do
        if not current[key] then
            TriggerEvent(AirOpsWeather.Events.warningRemoved, warning)
            publish('warningRemoved', warning, AirOpsWeather.Events.warningsChanged)
        end
    end

    previousWarnings = current
    publish('warningsUpdated', warnings, AirOpsWeather.Events.warningsChanged)
end)


AddEventHandler(AirOpsWeather.Events.zoneRegistered, function(zone)
    publish('zoneRegistered', zone, AirOpsWeather.Events.zoneRegistered)
end)

AddEventHandler(
    AirOpsWeather.Events.zoneChanged,
    function(zone, previous, current, reason)
        publish('zoneChanged', {
            zone = zone,
            previous = previous,
            current = current,
            reason = reason
        }, AirOpsWeather.Events.zoneChanged)
    end
)


AddEventHandler(AirOpsWeather.Events.jsonUpdated, function(document)
    publish('jsonUpdated', document, AirOpsWeather.Events.jsonUpdated)
end)
