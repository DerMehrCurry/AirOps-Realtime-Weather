AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.ClientAPI = AirOpsWeather.ClientAPI or {}

local lastState = nil

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

function AirOpsWeather.ClientAPI.SetState(state)
    lastState = clone(state)
end

function AirOpsWeather.ClientAPI.GetState()
    return clone(lastState)
end

function AirOpsWeather.ClientAPI.GetWeather()
    if not lastState then
        return nil
    end

    return {
        weather = lastState.weatherOverride
            and lastState.weatherOverride.active
            and lastState.weatherOverride.value
            or lastState.currentWeather,
        temperatureCelsius = lastState.temperature,
        humidityPercent = lastState.humidity,
        pressureHpa = lastState.pressure,
        precipitationMm = lastState.precipitation,
        cloudCoverPercent = lastState.cloudCover,
        visibilityMeters = lastState.visibility,
        wind = {
            speedKmh = lastState.windSpeed,
            gustsKmh = lastState.windGusts,
            directionDegrees = lastState.windDirection
        },
        stale = lastState.stale,
        mode = lastState.mode
    }
end

function AirOpsWeather.ClientAPI.GetTime()
    if not lastState then
        return nil
    end

    local now = os.time()
    local override = lastState.timeOverride or { active = false }
    local secondsOfDay

    if override.active then
        secondsOfDay = (
            (tonumber(override.secondsOfDay) or 0)
            + math.max(0, now - (tonumber(override.setAt) or now))
        ) % 86400
    else
        secondsOfDay = (
            now + (tonumber(lastState.timezoneOffsetSeconds) or 0)
        ) % 86400
    end

    return {
        hour = math.floor(secondsOfDay / 3600),
        minute = math.floor((secondsOfDay % 3600) / 60),
        second = math.floor(secondsOfDay % 60),
        secondsOfDay = secondsOfDay,
        mode = override.active and 'manual' or 'realtime'
    }
end

exports('GetCurrentState', function()
    return AirOpsWeather.ClientAPI.GetState()
end)

exports('GetCurrentWeather', function()
    return AirOpsWeather.ClientAPI.GetWeather()
end)

exports('GetCurrentTime', function()
    return AirOpsWeather.ClientAPI.GetTime()
end)

exports('getCurrentState', function()
    return AirOpsWeather.ClientAPI.GetState()
end)

exports('getCurrentWeather', function()
    return AirOpsWeather.ClientAPI.GetWeather()
end)

exports('getCurrentTime', function()
    return AirOpsWeather.ClientAPI.GetTime()
end)
