AirOpsWeather = AirOpsWeather or {}

local WEATHER_ORDER = {
    EXTRASUNNY = 1,
    CLEAR = 2,
    CLOUDS = 3,
    OVERCAST = 4,
    RAIN = 5,
    THUNDER = 6
}

local ORDER_WEATHER = {
    [1] = 'EXTRASUNNY',
    [2] = 'CLEAR',
    [3] = 'CLOUDS',
    [4] = 'OVERCAST',
    [5] = 'RAIN',
    [6] = 'THUNDER'
}

local WEATHER_CLASS = {
    EXTRASUNNY = 'stable',
    CLEAR = 'stable',
    CLOUDS = 'normal',
    OVERCAST = 'changing',
    RAIN = 'precipitation',
    THUNDER = 'severe',
    FOGGY = 'changing',
    SNOWLIGHT = 'precipitation',
    BLIZZARD = 'severe'
}

local function valueAt(values, index)
    if type(values) ~= 'table' then
        return nil
    end

    return values[index]
end

local function hourlyData(forecast, index)
    return {
        weatherCode = valueAt(forecast.weather_code, index),
        precipitation = valueAt(forecast.precipitation, index),
        cloudCover = valueAt(forecast.cloud_cover, index),
        visibility = valueAt(forecast.visibility, index),
        windSpeed = valueAt(forecast.wind_speed_10m, index),
        windDirection = valueAt(forecast.wind_direction_10m, index),
        windGusts = valueAt(forecast.wind_gusts_10m, index)
    }
end

local function nextLocalHourTimestamp(timezoneOffsetSeconds)
    local now = os.time()
    local localEpoch = now + (tonumber(timezoneOffsetSeconds) or 0)
    local secondsIntoHour = localEpoch % 3600
    local remaining = 3600 - secondsIntoHour

    if remaining <= 0 then
        remaining = 3600
    end

    return now + remaining
end

local function deterministicHash(value)
    local hash = 5381

    for index = 1, #value do
        hash = ((hash * 33) + string.byte(value, index)) % 2147483647
    end

    return hash
end

local function deterministicOffsetSeconds(providerTime, weather)
    if not Config.Forecast.flexibleTransitions then
        return 0
    end

    local maximumMinutes = math.max(
        0,
        tonumber(Config.Forecast.maximumOffsetMinutes) or 20
    )
    local maximumSeconds = math.floor(maximumMinutes * 60)

    if maximumSeconds == 0 then
        return 0
    end

    local seed = table.concat({
        tostring(Config.Location.name or ''),
        tostring(providerTime or ''),
        tostring(weather or '')
    }, '|')

    local range = (maximumSeconds * 2) + 1
    return (deterministicHash(seed) % range) - maximumSeconds
end

local function compactTargets(entries, currentWeather)
    if not Config.Forecast.compressIdenticalStates then
        return entries
    end

    local result = {}
    local previousWeather = currentWeather

    for _, entry in ipairs(entries) do
        if entry.weather ~= previousWeather then
            result[#result + 1] = entry
            previousWeather = entry.weather
        end
    end

    return result
end

local function removeShortReversals(entries)
    local minimum = tonumber(Config.Forecast.minimumTimelineStateSeconds) or 0

    if minimum <= 0 or #entries < 3 then
        return entries
    end

    local result = {}
    local index = 1

    while index <= #entries do
        local current = entries[index]
        local nextEntry = entries[index + 1]
        local afterNext = entries[index + 2]

        if nextEntry
            and afterNext
            and current.weather == afterNext.weather
            and (afterNext.at - nextEntry.at) < minimum then
            result[#result + 1] = current
            index = index + 3
        else
            result[#result + 1] = current
            index = index + 1
        end
    end

    return result
end

local function transitionPath(fromWeather, toWeather)
    if fromWeather == toWeather then
        return {}
    end

    local fromOrder = WEATHER_ORDER[fromWeather]
    local toOrder = WEATHER_ORDER[toWeather]

    if not fromOrder or not toOrder then
        -- Fog and snow do not belong to the cloud/rain intensity ladder. They are
        -- therefore applied as a direct, but still smoothly blended, target.
        return { toWeather }
    end

    local path = {}
    local direction = toOrder > fromOrder and 1 or -1

    for order = fromOrder + direction, toOrder, direction do
        path[#path + 1] = ORDER_WEATHER[order]
    end

    return path
end

local function transitionDuration(weather)
    local durations = Config.Forecast.transitionSecondsByClass or {}
    local class = WEATHER_CLASS[weather] or 'normal'

    return tonumber(durations[class])
        or tonumber(Config.Weather.transitionSeconds)
        or 180
end

local function expandTransitionTargets(targets, currentWeather)
    local result = {}
    local previousWeather = currentWeather
    local now = os.time()
    local leadStepSeconds = math.max(
        60,
        math.floor((tonumber(Config.Forecast.transitionStepMinutes) or 8) * 60)
    )
    local minimumFutureSeconds = math.max(
        30,
        tonumber(Config.Forecast.minimumFutureSeconds) or 120
    )
    local minimumSpacingSeconds = math.max(
        30,
        tonumber(Config.Forecast.minimumEntrySpacingSeconds) or 180
    )
    local lastAt = now

    for _, target in ipairs(targets) do
        local path = transitionPath(previousWeather, target.weather)
        local firstAt = target.at - (math.max(0, #path - 1) * leadStepSeconds)

        for pathIndex, weather in ipairs(path) do
            local plannedAt = firstAt + ((pathIndex - 1) * leadStepSeconds)
            plannedAt = math.max(plannedAt, now + minimumFutureSeconds)
            plannedAt = math.max(plannedAt, lastAt + minimumSpacingSeconds)

            result[#result + 1] = {
                weather = weather,
                class = WEATHER_CLASS[weather] or target.class,
                at = plannedAt,
                providerAt = target.providerAt,
                providerTime = target.providerTime,
                offsetSeconds = target.offsetSeconds,
                transitionSeconds = transitionDuration(weather),
                intermediate = pathIndex < #path,
                targetWeather = target.weather
            }

            lastAt = plannedAt
        end

        previousWeather = target.weather
    end

    return result
end

local function scheduleTimeline(entries, generation)
    for _, entry in ipairs(entries) do
        local delayMilliseconds = math.max(0, (entry.at - os.time()) * 1000)

        SetTimeout(delayMilliseconds, function()
            if generation ~= AirOpsWeather.GetTimelineGeneration() then
                return
            end

            local cache = AirOpsWeather.GetCache()
            if cache.timeline[1] ~= entry then
                return
            end

            table.remove(cache.timeline, 1)
            local changed = AirOpsWeather.ApplyWeatherCandidate(
                entry.weather,
                entry.class,
                entry.intermediate and 'forecast transition' or 'forecast target',
                false,
                entry.transitionSeconds
            )

            if changed then
                AirOpsWeather.BroadcastState(-1)
            end
        end)
    end
end

function AirOpsWeather.BuildForecastTimeline(forecast)
    if type(forecast) ~= 'table' or type(forecast.time) ~= 'table' then
        AirOpsWeather.SetTimeline({})
        AirOpsWeather.Debug('No usable hourly forecast was returned.')
        return {}
    end

    local cache = AirOpsWeather.GetCache()
    local firstProviderAt = nextLocalHourTimestamp(cache.timezoneOffsetSeconds)
    local targets = {}

    -- Open-Meteo starts forecast_hours with the current hour. Index 2 represents
    -- the next provider hour. AirOps treats it as a forecast target, not as a hard
    -- visible switch at exactly the full hour.
    for index = 2, #forecast.time do
        local weather, weatherClass = AirOpsWeather.MapWeather(hourlyData(forecast, index))
        local providerAt = firstProviderAt + ((index - 2) * 3600)
        local offsetSeconds = deterministicOffsetSeconds(forecast.time[index], weather)

        targets[#targets + 1] = {
            weather = weather,
            class = weatherClass,
            providerAt = providerAt,
            at = providerAt + offsetSeconds,
            providerTime = forecast.time[index],
            offsetSeconds = offsetSeconds
        }
    end

    targets = compactTargets(targets, cache.currentWeather)
    targets = removeShortReversals(targets)

    local entries = expandTransitionTargets(targets, cache.currentWeather)
    local generation = AirOpsWeather.SetTimeline(entries)
    scheduleTimeline(entries, generation)

    if entries[1] then
        AirOpsWeather.Debug(
            'Flexible forecast timeline created with %d steps; next is %s in %ds (provider offset %+ds).',
            #entries,
            entries[1].weather,
            math.max(0, entries[1].at - os.time()),
            entries[1].offsetSeconds or 0
        )
    else
        AirOpsWeather.Debug('Forecast timeline contains no weather changes.')
    end

    return entries
end
