AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.IntegrationMetrics = AirOpsWeather.IntegrationMetrics or {}

local metrics = {
    eventsPublished = 0,
    listeners = 0,
    jsonExports = 0,
    jsonPrettyExports = 0,
    webhookQueued = 0,
    webhookSent = 0,
    webhookFailed = 0,
    webhookRetried = 0,
    webhookDropped = 0,
    sdkCalls = 0,
    eventsByName = {}
}

function AirOpsWeather.IntegrationMetrics.RecordEvent(eventName)
    metrics.eventsPublished = metrics.eventsPublished + 1
    metrics.eventsByName[eventName] =
        (metrics.eventsByName[eventName] or 0) + 1
end

function AirOpsWeather.IntegrationMetrics.RecordListener(delta)
    metrics.listeners = math.max(
        0,
        metrics.listeners + (tonumber(delta) or 0)
    )
end

function AirOpsWeather.IntegrationMetrics.Increment(name, amount)
    if type(metrics[name]) ~= 'number' then
        return false
    end

    metrics[name] = metrics[name] + (tonumber(amount) or 1)
    return true
end

function AirOpsWeather.IntegrationMetrics.Get()
    local result = {}

    for key, value in pairs(metrics) do
        if type(value) == 'table' then
            result[key] = {}
            for childKey, childValue in pairs(value) do
                result[key][childKey] = childValue
            end
        else
            result[key] = value
        end
    end

    if AirOpsWeather.Webhooks and AirOpsWeather.Webhooks.GetQueueSize then
        result.webhookQueue = AirOpsWeather.Webhooks.GetQueueSize()
    else
        result.webhookQueue = 0
    end

    return result
end

exports('GetIntegrationMetrics', function()
    return AirOpsWeather.IntegrationMetrics.Get()
end)
