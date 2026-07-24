AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Override = AirOpsWeather.Override or {}

local expiryGeneration = {
    weather = 0,
    time = 0
}

local state = {
    weather = {
        active = false,
        value = nil,
        expiresAt = 0,
        source = nil,
        transitionSeconds = nil
    },
    time = {
        active = false,
        secondsOfDay = 0,
        setAt = 0,
        expiresAt = 0,
        source = nil
    }
}

local VALID_WEATHER = {
    EXTRASUNNY = true,
    CLEAR = true,
    NEUTRAL = true,
    SMOG = true,
    FOGGY = true,
    CLOUDS = true,
    OVERCAST = true,
    CLEARING = true,
    RAIN = true,
    THUNDER = true,
    SNOW = true,
    BLIZZARD = true,
    SNOWLIGHT = true,
    XMAS = true,
    HALLOWEEN = true
}

local function normalizeDurationMinutes(value)
    local minutes = tonumber(value)
    if not minutes or minutes <= 0 then
        return 0
    end

    return math.floor(minutes * 60)
end

local function broadcast()
    if AirOpsWeather.BroadcastState then
        AirOpsWeather.BroadcastState(-1, true)
    end
end

local function scheduleExpiry(scope, expiresAt)
    expiryGeneration[scope] = expiryGeneration[scope] + 1
    local generation = expiryGeneration[scope]

    if not expiresAt or expiresAt <= 0 then
        return
    end

    local delayMilliseconds = math.max(
        0,
        (expiresAt - os.time()) * 1000
    )

    SetTimeout(delayMilliseconds, function()
        if generation ~= expiryGeneration[scope] then
            return
        end

        if scope == 'weather'
            and state.weather.active
            and state.weather.expiresAt > 0
            and os.time() >= state.weather.expiresAt then
            AirOpsWeather.Override.ClearWeather('expired')
        elseif scope == 'time'
            and state.time.active
            and state.time.expiresAt > 0
            and os.time() >= state.time.expiresAt then
            AirOpsWeather.Override.ClearTime('expired')
        end
    end)
end

function AirOpsWeather.Override.IsWeatherActive()
    return state.weather.active
end

function AirOpsWeather.Override.IsTimeActive()
    return state.time.active
end

function AirOpsWeather.Override.IsWeatherTypeValid(weather)
    return VALID_WEATHER[string.upper(tostring(weather or ''))] == true
end

function AirOpsWeather.Override.GetState()
    return {
        weather = {
            active = state.weather.active,
            value = state.weather.value,
            expiresAt = state.weather.expiresAt,
            source = state.weather.source,
            transitionSeconds = state.weather.transitionSeconds
        },
        time = {
            active = state.time.active,
            secondsOfDay = state.time.secondsOfDay,
            setAt = state.time.setAt,
            expiresAt = state.time.expiresAt,
            source = state.time.source
        }
    }
end

function AirOpsWeather.Override.SetWeather(weather, durationMinutes, source, transitionSeconds)
    weather = string.upper(tostring(weather or ''))

    if not AirOpsWeather.Override.IsWeatherTypeValid(weather) then
        return false, ('unsupported weather type: %s'):format(weather)
    end

    local durationSeconds = normalizeDurationMinutes(durationMinutes)
    state.weather.active = true
    state.weather.value = weather
    state.weather.expiresAt = durationSeconds > 0 and (os.time() + durationSeconds) or 0
    state.weather.source = source or 'manual'
    state.weather.transitionSeconds = tonumber(transitionSeconds)
        or tonumber(Config.Override.weatherTransitionSeconds)
        or tonumber(Config.Weather.transitionSeconds)
        or 180

    scheduleExpiry('weather', state.weather.expiresAt)

    local cache = AirOpsWeather.GetCache()
    AirOpsWeather.SetWeather(weather, 'manual', state.weather.transitionSeconds)

    local disasterOwnsWeather = AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.IsExternalWeatherControlActive
        and AirOpsWeather.Integrations.IsExternalWeatherControlActive()

    if not disasterOwnsWeather
        and AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.IsNaturalDisastersEnabled
        and AirOpsWeather.Integrations.IsNaturalDisastersEnabled() then
        AirOpsWeather.Integrations.ApplyNaturalDisastersWeather(weather, true)
    end

    AirOpsWeather.Info(
        'Manual weather override enabled: %s%s.',
        weather,
        state.weather.expiresAt > 0 and (' for ' .. durationMinutes .. ' minute(s)') or ''
    )

    TriggerEvent(AirOpsWeather.Events.weatherChanged, cache.previousWeather, weather, 'manual override')
    TriggerEvent(AirOpsWeather.Events.overrideStarted, 'weather', AirOpsWeather.Override.GetState())
    broadcast()
    return true
end

function AirOpsWeather.Override.SetTime(hour, minute, durationMinutes, source)
    hour = tonumber(hour)
    minute = tonumber(minute)

    if not hour or not minute
        or hour < 0 or hour > 23
        or minute < 0 or minute > 59 then
        return false, 'time must use hour 0-23 and minute 0-59'
    end

    hour = math.floor(hour)
    minute = math.floor(minute)

    local durationSeconds = normalizeDurationMinutes(durationMinutes)
    state.time.active = true
    state.time.secondsOfDay = (hour * 3600) + (minute * 60)
    state.time.setAt = os.time()
    state.time.expiresAt = durationSeconds > 0 and (os.time() + durationSeconds) or 0
    state.time.source = source or 'manual'

    scheduleExpiry('time', state.time.expiresAt)

    TriggerEvent(AirOpsWeather.Events.overrideStarted, 'time', AirOpsWeather.Override.GetState())

    AirOpsWeather.Info(
        'Manual time override enabled: %02d:%02d%s.',
        hour,
        minute,
        state.time.expiresAt > 0 and (' for ' .. durationMinutes .. ' minute(s)') or ''
    )

    broadcast()
    return true
end

function AirOpsWeather.Override.ClearWeather(reason)
    if not state.weather.active then
        return false
    end

    state.weather.active = false
    state.weather.value = nil
    state.weather.expiresAt = 0
    state.weather.source = nil
    state.weather.transitionSeconds = nil
    expiryGeneration.weather = expiryGeneration.weather + 1

    local cache = AirOpsWeather.GetCache()
    local realtimeWeather, realtimeClass = AirOpsWeather.MapWeather(cache.raw or {})
    realtimeWeather = realtimeWeather or Config.Weather.fallback

    AirOpsWeather.SetWeather(realtimeWeather, realtimeClass or 'normal', Config.Weather.transitionSeconds)

    local disasterOwnsWeather = AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.IsExternalWeatherControlActive
        and AirOpsWeather.Integrations.IsExternalWeatherControlActive()

    if not disasterOwnsWeather
        and AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.IsNaturalDisastersEnabled
        and AirOpsWeather.Integrations.IsNaturalDisastersEnabled() then
        AirOpsWeather.Integrations.ApplyNaturalDisastersWeather(realtimeWeather, true)
    end

    AirOpsWeather.Info('Manual weather override cleared%s.', reason and (' (' .. reason .. ')') or '')
    TriggerEvent(AirOpsWeather.Events.overrideEnded, 'weather', reason, AirOpsWeather.Override.GetState())
    broadcast()
    return true
end

function AirOpsWeather.Override.ClearTime(reason)
    if not state.time.active then
        return false
    end

    state.time.active = false
    state.time.secondsOfDay = 0
    state.time.setAt = 0
    state.time.expiresAt = 0
    state.time.source = nil
    expiryGeneration.time = expiryGeneration.time + 1

    AirOpsWeather.Info('Manual time override cleared%s.', reason and (' (' .. reason .. ')') or '')
    TriggerEvent(AirOpsWeather.Events.overrideEnded, 'time', reason, AirOpsWeather.Override.GetState())
    broadcast()
    return true
end

function AirOpsWeather.Override.Clear(scope, reason)
    scope = string.lower(tostring(scope or 'all'))
    local changed = false

    if scope == 'weather' or scope == 'all' then
        changed = AirOpsWeather.Override.ClearWeather(reason) or changed
    end

    if scope == 'time' or scope == 'all' then
        changed = AirOpsWeather.Override.ClearTime(reason) or changed
    end

    return changed
end


exports('setWeatherOverride', function(weather, durationMinutes, source, transitionSeconds)
    return AirOpsWeather.Override.SetWeather(weather, durationMinutes, source, transitionSeconds)
end)

exports('setTimeOverride', function(hour, minute, durationMinutes, source)
    return AirOpsWeather.Override.SetTime(hour, minute, durationMinutes, source)
end)

exports('clearOverride', function(scope, reason)
    return AirOpsWeather.Override.Clear(scope, reason)
end)

exports('getOverrideState', function()
    return AirOpsWeather.Override.GetState()
end)
