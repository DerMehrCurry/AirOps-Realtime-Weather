AirOpsWeather = AirOpsWeather or {}

local cache = {
    valid = false,
    currentWeather = Config.Weather.fallback,
    previousWeather = nil,
    weatherClass = 'normal',
    raw = {},
    forecast = {},
    timeline = {},
    timelineGeneration = 0,
    timezoneOffsetSeconds = 0,
    fetchedAt = 0,
    weatherChangedAt = 0,
    nextPollAt = 0,
    failureCount = 0,
    transitionSeconds = Config.Weather.transitionSeconds
}

function AirOpsWeather.GetCache()
    return cache
end

function AirOpsWeather.SetSuccessfulFetch(payload)
    cache.valid = true
    cache.raw = payload.current or {}
    cache.forecast = payload.forecast or {}
    cache.timezoneOffsetSeconds = tonumber(payload.timezoneOffsetSeconds) or 0
    cache.fetchedAt = os.time()
    cache.failureCount = 0
end

function AirOpsWeather.SetWeather(weather, class, transitionSeconds)
    local now = os.time()

    if weather ~= cache.currentWeather then
        cache.previousWeather = cache.currentWeather
        cache.currentWeather = weather
        cache.weatherChangedAt = now
    elseif cache.weatherChangedAt == 0 then
        cache.weatherChangedAt = now
    end

    cache.weatherClass = class or 'normal'
    cache.transitionSeconds = tonumber(transitionSeconds) or Config.Weather.transitionSeconds
end

function AirOpsWeather.CanChangeWeather(candidate)
    if candidate == cache.currentWeather or cache.weatherChangedAt == 0 then
        return true
    end

    return (os.time() - cache.weatherChangedAt) >= Config.Weather.minimumStateDurationSeconds
end

function AirOpsWeather.SetTimeline(entries)
    cache.timelineGeneration = cache.timelineGeneration + 1
    cache.timeline = entries or {}
    return cache.timelineGeneration
end

function AirOpsWeather.GetTimelineGeneration()
    return cache.timelineGeneration
end

function AirOpsWeather.RegisterFailure()
    cache.failureCount = cache.failureCount + 1
    return cache.failureCount
end

function AirOpsWeather.SetNextPoll(timestamp)
    cache.nextPollAt = timestamp
end

function AirOpsWeather.PublicState()
    local nextEntry = cache.timeline[1]
    local overrideState = AirOpsWeather.Override
        and AirOpsWeather.Override.GetState
        and AirOpsWeather.Override.GetState()
        or { weather = { active = false }, time = { active = false } }

    return {
        version = AirOpsWeather.Version,
        valid = cache.valid,
        serverUnixTime = os.time(),
        timezoneOffsetSeconds = cache.timezoneOffsetSeconds,
        currentWeather = cache.currentWeather,
        previousWeather = cache.previousWeather,
        weatherChangedAt = cache.weatherChangedAt,
        transitionSeconds = cache.transitionSeconds,
        windSpeed = tonumber(cache.raw.windSpeed) or 0.0,
        windDirection = tonumber(cache.raw.windDirection) or 0.0,
        windGusts = tonumber(cache.raw.windGusts) or 0.0,
        temperature = tonumber(cache.raw.temperature),
        fetchedAt = cache.fetchedAt,
        nextPollAt = cache.nextPollAt,
        nextForecastWeather = nextEntry and nextEntry.weather or nil,
        nextForecastAt = nextEntry and nextEntry.at or nil,
        mode = overrideState.weather.active and 'manual' or 'realtime',
        weatherOverride = overrideState.weather,
        timeOverride = overrideState.time
    }
end
