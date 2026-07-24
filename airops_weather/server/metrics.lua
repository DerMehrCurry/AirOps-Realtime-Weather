AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Metrics = AirOpsWeather.Metrics or {}

local metrics = {
    startedAt = os.time(),
    apiRequests = 0,
    apiSuccesses = 0,
    apiFailures = 0,
    apiTimeouts = 0,
    lastRequestDurationMilliseconds = 0,
    averageRequestDurationMilliseconds = 0,
    totalRequestDurationMilliseconds = 0,
    broadcasts = 0,
    suppressedBroadcasts = 0,
    directSyncs = 0,
    timelineBuilds = 0,
    timelineExecutions = 0,
    weatherChanges = 0,
    lastBroadcastAt = 0,
    lastSuccessfulRequestAt = 0,
    lastFailedRequestAt = 0
}

function AirOpsWeather.Metrics.Increment(name, amount)
    if metrics[name] == nil then
        return
    end

    metrics[name] = metrics[name] + (tonumber(amount) or 1)
end

function AirOpsWeather.Metrics.RecordRequest(success, durationMilliseconds, timedOut)
    metrics.apiRequests = metrics.apiRequests + 1
    metrics.lastRequestDurationMilliseconds = math.max(
        0,
        math.floor(tonumber(durationMilliseconds) or 0)
    )

    if success then
        metrics.apiSuccesses = metrics.apiSuccesses + 1
        metrics.lastSuccessfulRequestAt = os.time()
        metrics.totalRequestDurationMilliseconds =
            metrics.totalRequestDurationMilliseconds
            + metrics.lastRequestDurationMilliseconds

        metrics.averageRequestDurationMilliseconds = math.floor(
            metrics.totalRequestDurationMilliseconds
            / math.max(1, metrics.apiSuccesses)
        )
    else
        metrics.apiFailures = metrics.apiFailures + 1
        metrics.lastFailedRequestAt = os.time()

        if timedOut then
            metrics.apiTimeouts = metrics.apiTimeouts + 1
        end
    end
end

function AirOpsWeather.Metrics.RecordBroadcast(target, suppressed)
    if suppressed then
        metrics.suppressedBroadcasts = metrics.suppressedBroadcasts + 1
        return
    end

    if target and target ~= -1 then
        metrics.directSyncs = metrics.directSyncs + 1
    else
        metrics.broadcasts = metrics.broadcasts + 1
        metrics.lastBroadcastAt = os.time()
    end
end

function AirOpsWeather.Metrics.Get()
    local result = {}

    for key, value in pairs(metrics) do
        result[key] = value
    end

    result.uptimeSeconds = os.time() - metrics.startedAt
    return result
end

exports('getPerformanceMetrics', function()
    return AirOpsWeather.Metrics.Get()
end)
