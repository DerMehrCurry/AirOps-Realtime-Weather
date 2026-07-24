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
    transitionSeconds = Config.Weather.transitionSeconds,
    lastBroadcastSnapshot = nil,
    staleWarningShown = false
}

local function angularDifference(first, second)
    first = tonumber(first) or 0
    second = tonumber(second) or 0
    local difference = math.abs(first - second) % 360
    return math.min(difference, 360 - difference)
end

local function snapshot()
    return {
        weather = cache.currentWeather,
        windSpeed = tonumber(cache.raw.windSpeed) or 0,
        windDirection = tonumber(cache.raw.windDirection) or 0,
        temperature = tonumber(cache.raw.temperature) or 0,
        timeOverrideActive = AirOpsWeather.Override
            and AirOpsWeather.Override.IsTimeActive
            and AirOpsWeather.Override.IsTimeActive()
            or false,
        weatherOverrideActive = AirOpsWeather.Override
            and AirOpsWeather.Override.IsWeatherActive
            and AirOpsWeather.Override.IsWeatherActive()
            or false
    }
end

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
    cache.staleWarningShown = false
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
    cache.transitionSeconds = tonumber(transitionSeconds)
        or Config.Weather.transitionSeconds
end

function AirOpsWeather.CanChangeWeather(candidate)
    if candidate == cache.currentWeather or cache.weatherChangedAt == 0 then
        return true
    end

    return (os.time() - cache.weatherChangedAt)
        >= Config.Weather.minimumStateDurationSeconds
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

function AirOpsWeather.IsCacheStale()
    if cache.fetchedAt <= 0 then
        return true
    end

    return (os.time() - cache.fetchedAt)
        > (tonumber(Config.Health.staleCacheSeconds) or 1800)
end

function AirOpsWeather.ShouldBroadcast(force)
    if force or not Config.Performance.suppressUnchangedBroadcasts then
        return true
    end

    local current = snapshot()
    local previous = cache.lastBroadcastSnapshot

    if not previous then
        return true
    end

    local heartbeat = tonumber(
        Config.Performance.heartbeatBroadcastSeconds
    ) or 900

    local lastBroadcastAt = AirOpsWeather.Metrics.Get().lastBroadcastAt or 0
    if lastBroadcastAt <= 0 or os.time() - lastBroadcastAt >= heartbeat then
        return true
    end

    if current.weather ~= previous.weather
        or current.timeOverrideActive ~= previous.timeOverrideActive
        or current.weatherOverrideActive ~= previous.weatherOverrideActive then
        return true
    end

    if math.abs(current.windSpeed - previous.windSpeed)
        >= (tonumber(Config.Performance.windChangeThresholdKmh) or 2.0) then
        return true
    end

    if angularDifference(current.windDirection, previous.windDirection)
        >= (tonumber(Config.Performance.windDirectionThresholdDegrees) or 15.0) then
        return true
    end

    if math.abs(current.temperature - previous.temperature)
        >= (tonumber(Config.Performance.temperatureChangeThresholdCelsius) or 1.0) then
        return true
    end

    return false
end

function AirOpsWeather.MarkBroadcastSnapshot()
    cache.lastBroadcastSnapshot = snapshot()
end

function AirOpsWeather.CheckCacheHealth()
    local stale = AirOpsWeather.IsCacheStale()

    if stale
        and Config.Health.warnWhenCacheBecomesStale
        and not cache.staleWarningShown then
        cache.staleWarningShown = true
        AirOpsWeather.Warn(
            'Weather cache is stale. Cached weather remains active until the provider recovers.'
        )
    end

    return {
        stale = stale,
        ageSeconds = cache.fetchedAt > 0 and (os.time() - cache.fetchedAt) or -1
    }
end

function AirOpsWeather.PublicState()
    local nextEntry = cache.timeline[1]
    local overrideState = AirOpsWeather.Override
        and AirOpsWeather.Override.GetState
        and AirOpsWeather.Override.GetState()
        or { weather = { active = false }, time = { active = false } }
    local health = AirOpsWeather.CheckCacheHealth()

    return {
        version = AirOpsWeather.Version,
        valid = cache.valid,
        stale = health.stale,
        cacheAgeSeconds = health.ageSeconds,
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
        humidity = tonumber(cache.raw.humidity),
        pressure = tonumber(cache.raw.pressure),
        precipitation = tonumber(cache.raw.precipitation) or 0.0,
        cloudCover = tonumber(cache.raw.cloudCover) or 0.0,
        visibility = tonumber(cache.raw.visibility) or 10000,
        fetchedAt = cache.fetchedAt,
        nextPollAt = cache.nextPollAt,
        nextForecastWeather = nextEntry and nextEntry.weather or nil,
        nextForecastAt = nextEntry and nextEntry.at or nil,
        mode = overrideState.weather.active and 'manual' or 'realtime',
        weatherOverride = overrideState.weather,
        timeOverride = overrideState.time
    }
end
