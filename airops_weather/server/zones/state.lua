AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.ZoneState = AirOpsWeather.ZoneState or {}

local stateByZone = {}

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

function AirOpsWeather.ZoneState.Set(zone, state, reason)
    local resolved, errorMessage = AirOpsWeather.Zones.Resolve(zone)
    if not resolved then
        return false, errorMessage
    end

    local previous = stateByZone[resolved]
    stateByZone[resolved] = clone(state)

    TriggerEvent(
        AirOpsWeather.Events.zoneChanged,
        resolved,
        clone(previous),
        clone(state),
        reason
    )

    AirOpsWeather.Integrations.Publish('zoneChanged', {
        zone = resolved,
        previous = previous,
        current = state,
        reason = reason
    })

    return true
end

function AirOpsWeather.ZoneState.Get(zone)
    local resolved, errorMessage = AirOpsWeather.Zones.Resolve(zone)
    if not resolved then
        return nil, errorMessage
    end

    if Config.Zones.sharedState then
        return AirOpsWeather.State.Get()
    end

    return clone(stateByZone[resolved])
end

function AirOpsWeather.ZoneState.Snapshot()
    local result = {}

    for _, zone in ipairs(AirOpsWeather.Zones.List()) do
        result[zone.name] =
            AirOpsWeather.ZoneState.Get(zone.name)
    end

    return result
end

exports('GetZoneState', function(zone)
    return AirOpsWeather.ZoneState.Get(zone)
end)

exports('GetZoneStates', function()
    return AirOpsWeather.ZoneState.Snapshot()
end)
