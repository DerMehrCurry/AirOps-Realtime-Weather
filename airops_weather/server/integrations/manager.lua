AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Integrations = AirOpsWeather.Integrations or {}

local listeners = {}
local listenerSequence = 0
local history = {}

local function clone(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

local function retainHistory(entry)
    history[#history + 1] = entry

    local limit = math.max(
        1,
        tonumber(Config.IntegrationBus.historySize) or 50
    )

    while #history > limit do
        table.remove(history, 1)
    end
end

function AirOpsWeather.Integrations.Subscribe(eventName, callback, owner)
    if type(eventName) ~= 'string' or eventName == '' then
        return nil, 'event name must not be empty'
    end

    if type(callback) ~= 'function' then
        return nil, 'listener callback must be a function'
    end

    listenerSequence = listenerSequence + 1

    listeners[eventName] = listeners[eventName] or {}
    listeners[eventName][listenerSequence] = {
        callback = callback,
        owner = tostring(owner or GetInvokingResource() or 'unknown')
    }

    AirOpsWeather.IntegrationMetrics.RecordListener(1)
    return listenerSequence
end

function AirOpsWeather.Integrations.Unsubscribe(listenerId)
    for _, eventListeners in pairs(listeners) do
        if eventListeners[listenerId] then
            eventListeners[listenerId] = nil
            AirOpsWeather.IntegrationMetrics.RecordListener(-1)
            return true
        end
    end

    return false
end

function AirOpsWeather.Integrations.Publish(eventName, payload, metadata)
    if not Config.IntegrationBus.enabled then
        return 0
    end

    local envelope = {
        event = eventName,
        payload = clone(payload),
        metadata = clone(metadata or {}),
        timestamp = os.time(),
        resourceVersion = AirOpsWeather.Version,
        apiVersion = AirOpsWeather.APIVersion
    }

    retainHistory(envelope)
    AirOpsWeather.IntegrationMetrics.RecordEvent(eventName)

    if Config.IntegrationBus.emitGenericEvent then
        TriggerEvent(AirOpsWeather.Events.integrationEvent, clone(envelope))
    end

    local count = 0
    local eventListeners = listeners[eventName] or {}

    for listenerId, listener in pairs(eventListeners) do
        local ok, errorMessage = pcall(
            listener.callback,
            clone(envelope.payload),
            clone(envelope)
        )

        if not ok then
            AirOpsWeather.Warn(
                'Integration listener %s (%s) failed for %s: %s',
                tostring(listenerId),
                listener.owner,
                eventName,
                tostring(errorMessage)
            )
        else
            count = count + 1
        end
    end

    return count
end

function AirOpsWeather.Integrations.GetHistory()
    return clone(history)
end

function AirOpsWeather.Integrations.GetListenerCount()
    local count = 0

    for _, eventListeners in pairs(listeners) do
        for _ in pairs(eventListeners) do
            count = count + 1
        end
    end

    return count
end

exports('RegisterIntegrationListener', function(eventName, callback)
    return AirOpsWeather.Integrations.Subscribe(
        eventName,
        callback,
        GetInvokingResource()
    )
end)

exports('RemoveIntegrationListener', function(listenerId)
    return AirOpsWeather.Integrations.Unsubscribe(listenerId)
end)

exports('GetIntegrationHistory', function()
    return AirOpsWeather.Integrations.GetHistory()
end)
