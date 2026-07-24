AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.API = AirOpsWeather.API or {}

local previousSignatures = {
    state = nil,
    profile = nil,
    forecast = nil,
    warnings = nil
}

local CATEGORY_RANK = {
    GREEN = 1,
    YELLOW = 2,
    ORANGE = 3,
    RED = 4
}

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

local function normalizeZone(zone)
    local resolved, errorMessage = AirOpsWeather.Zones.Resolve(zone)
    return resolved, errorMessage
end

local function supportsZone(zone)
    return AirOpsWeather.Zones.Exists(zone)
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or 0
    return math.max(minimum, math.min(maximum, value))
end

local function weatherClassFor(weather, fallback)
    local classes = {
        EXTRASUNNY = 'stable',
        CLEAR = 'stable',
        NEUTRAL = 'stable',
        CLOUDS = 'normal',
        SMOG = 'changing',
        OVERCAST = 'changing',
        CLEARING = 'changing',
        FOGGY = 'fog',
        RAIN = 'precipitation',
        SNOW = 'snow',
        SNOWLIGHT = 'snow',
        XMAS = 'snow',
        THUNDER = 'severe',
        BLIZZARD = 'severe',
        HALLOWEEN = 'severe'
    }

    return classes[string.upper(tostring(weather or ''))]
        or fallback
        or 'normal'
end

local function precipitationIntensity(raw, weather)
    local precipitation = tonumber(raw.precipitation) or 0
    local intensity = clamp(precipitation / 8.0, 0, 1)

    if weather == 'THUNDER' or weather == 'BLIZZARD' then
        intensity = math.max(intensity, 0.85)
    elseif weather == 'RAIN' or weather == 'SNOWLIGHT' then
        intensity = math.max(intensity, 0.35)
    end

    return intensity
end

local function roadCondition(weather, precipitation)
    weather = string.upper(tostring(weather or ''))
    precipitation = tonumber(precipitation) or 0

    if weather == 'SNOW'
        or weather == 'SNOWLIGHT'
        or weather == 'BLIZZARD'
        or weather == 'XMAS' then
        return 'SNOW'
    end

    if weather == 'RAIN' or weather == 'THUNDER' or precipitation >= 0.2 then
        return precipitation >= 4.0 and 'FLOODED' or 'WET'
    end

    if weather == 'FOGGY' or weather == 'SMOG' then
        return 'DAMP'
    end

    return 'DRY'
end

local function speedFactor(condition)
    local factors = {
        DRY = 1.0,
        DAMP = 0.9,
        WET = 0.85,
        SNOW = 0.7,
        FLOODED = 0.6
    }

    return factors[condition] or 1.0
end

local function raiseCategory(current, candidate)
    if CATEGORY_RANK[candidate] > CATEGORY_RANK[current] then
        return candidate
    end

    return current
end

function AirOpsWeather.API.GetFlightConditions(profile)
    profile = profile or AirOpsWeather.API.GetWeatherProfile()

    local thresholds = Config.API.flight or {}
    local category = 'GREEN'
    local reasons = {}
    local wind = tonumber(profile.wind.speedKmh) or 0
    local gusts = tonumber(profile.wind.gustsKmh) or 0
    local visibility = tonumber(profile.visibilityMeters) or 10000

    if wind >= (tonumber(thresholds.redWindKmh) or 60) then
        category = raiseCategory(category, 'RED')
        reasons[#reasons + 1] = 'extreme_wind'
    elseif wind >= (tonumber(thresholds.orangeWindKmh) or 45) then
        category = raiseCategory(category, 'ORANGE')
        reasons[#reasons + 1] = 'strong_wind'
    elseif wind >= (tonumber(thresholds.yellowWindKmh) or 30) then
        category = raiseCategory(category, 'YELLOW')
        reasons[#reasons + 1] = 'elevated_wind'
    end

    if gusts >= (tonumber(thresholds.redGustKmh) or 70) then
        category = raiseCategory(category, 'RED')
        reasons[#reasons + 1] = 'extreme_gusts'
    elseif gusts >= (tonumber(thresholds.orangeGustKmh) or 55) then
        category = raiseCategory(category, 'ORANGE')
        reasons[#reasons + 1] = 'strong_gusts'
    elseif gusts >= (tonumber(thresholds.yellowGustKmh) or 40) then
        category = raiseCategory(category, 'YELLOW')
        reasons[#reasons + 1] = 'elevated_gusts'
    end

    if visibility <= (tonumber(thresholds.redVisibilityMeters) or 1000) then
        category = raiseCategory(category, 'RED')
        reasons[#reasons + 1] = 'critical_visibility'
    elseif visibility <= (tonumber(thresholds.orangeVisibilityMeters) or 2500) then
        category = raiseCategory(category, 'ORANGE')
        reasons[#reasons + 1] = 'poor_visibility'
    elseif visibility <= (tonumber(thresholds.yellowVisibilityMeters) or 5000) then
        category = raiseCategory(category, 'YELLOW')
        reasons[#reasons + 1] = 'reduced_visibility'
    end

    if profile.weather == 'THUNDER' or profile.weather == 'BLIZZARD' then
        category = 'RED'
        reasons[#reasons + 1] = 'severe_weather'
    elseif profile.class == 'precipitation' or profile.class == 'snow' then
        category = raiseCategory(category, 'YELLOW')
        reasons[#reasons + 1] = 'precipitation'
    end

    return {
        category = category,
        flyable = category ~= 'RED',
        reasons = reasons,
        evaluatedAt = os.time()
    }
end

function AirOpsWeather.API.GetWarnings(profile)
    profile = profile or AirOpsWeather.API.GetWeatherProfile()

    local thresholds = Config.API.warnings or {}
    local warnings = {}
    local wind = tonumber(profile.wind.speedKmh) or 0
    local visibility = tonumber(profile.visibilityMeters) or 10000
    local precipitation = tonumber(profile.precipitationMm) or 0

    local function add(code, severity, message)
        warnings[#warnings + 1] = {
            code = code,
            severity = severity,
            message = message
        }
    end

    if profile.weather == 'THUNDER' then
        add('THUNDERSTORM', 'RED', 'Thunderstorm conditions')
    elseif profile.weather == 'BLIZZARD' then
        add('BLIZZARD', 'RED', 'Blizzard conditions')
    end

    if wind >= (tonumber(thresholds.severeWindKmh) or 55) then
        add('SEVERE_WIND', 'RED', 'Severe wind')
    elseif wind >= (tonumber(thresholds.strongWindKmh) or 35) then
        add('STRONG_WIND', 'ORANGE', 'Strong wind')
    end

    if visibility <= (tonumber(thresholds.criticalVisibilityMeters) or 1200) then
        add('CRITICAL_VISIBILITY', 'RED', 'Critical visibility')
    elseif visibility <= (tonumber(thresholds.lowVisibilityMeters) or 3000) then
        add('LOW_VISIBILITY', 'ORANGE', 'Low visibility')
    end

    if precipitation >= (tonumber(thresholds.extremePrecipitationMm) or 8.0) then
        add('EXTREME_PRECIPITATION', 'RED', 'Extreme precipitation')
    elseif precipitation >= (tonumber(thresholds.heavyPrecipitationMm) or 4.0) then
        add('HEAVY_PRECIPITATION', 'ORANGE', 'Heavy precipitation')
    end

    return warnings
end

function AirOpsWeather.API.GetWeatherProfile(zone)
    local resolvedZone, zoneError = normalizeZone(zone)
    if not resolvedZone then
        return nil, zoneError
    end
    zone = resolvedZone
    local cache = AirOpsWeather.GetCache()
    local state = AirOpsWeather.PublicState()
    local raw = cache.raw or {}
    local override = state.weatherOverride or { active = false }
    local effectiveWeather = override.active and override.value or state.currentWeather
    local class = weatherClassFor(effectiveWeather, cache.weatherClass)
    local condition = roadCondition(effectiveWeather, raw.precipitation)

    local profile = {
        apiVersion = AirOpsWeather.APIVersion,
        zone = zone,
        resourceVersion = AirOpsWeather.Version,
        location = {
            name = Config.Location.name,
            latitude = Config.Location.latitude,
            longitude = Config.Location.longitude,
            timezone = Config.Location.timezone
        },
        weather = effectiveWeather,
        class = class,
        intensity = precipitationIntensity(raw, effectiveWeather),
        temperatureCelsius = tonumber(raw.temperature),
        humidityPercent = tonumber(raw.humidity),
        pressureHpa = tonumber(raw.pressure),
        precipitationMm = tonumber(raw.precipitation) or 0,
        cloudCoverPercent = tonumber(raw.cloudCover) or 0,
        visibilityMeters = tonumber(raw.visibility) or 10000,
        wind = {
            speedKmh = tonumber(raw.windSpeed) or 0,
            gustsKmh = tonumber(raw.windGusts) or 0,
            directionDegrees = tonumber(raw.windDirection) or 0
        },
        road = {
            condition = condition,
            recommendedSpeedFactor = speedFactor(condition)
        },
        source = {
            provider = Config.Provider.name,
            mode = override.active and 'manual' or 'realtime',
            override = override.active,
            stale = state.stale,
            fetchedAt = state.fetchedAt
        },
        transition = {
            previousWeather = state.previousWeather,
            seconds = state.transitionSeconds,
            changedAt = state.weatherChangedAt
        },
        generatedAt = os.time()
    }

    profile.flight = AirOpsWeather.API.GetFlightConditions(profile)
    profile.warnings = AirOpsWeather.API.GetWarnings(profile)
    return profile
end

function AirOpsWeather.API.GetTime(zone)
    local resolvedZone, zoneError = normalizeZone(zone)
    if not resolvedZone then
        return nil, zoneError
    end
    zone = resolvedZone
    local state = AirOpsWeather.PublicState()
    local override = state.timeOverride or { active = false }
    local unixTime = os.time()
    local secondsOfDay

    if override.active then
        secondsOfDay = (
            (tonumber(override.secondsOfDay) or 0)
            + math.max(0, unixTime - (tonumber(override.setAt) or unixTime))
        ) % 86400
    else
        secondsOfDay = (unixTime + (tonumber(state.timezoneOffsetSeconds) or 0)) % 86400
    end

    return {
        zone = zone,
        hour = math.floor(secondsOfDay / 3600),
        minute = math.floor((secondsOfDay % 3600) / 60),
        second = math.floor(secondsOfDay % 60),
        secondsOfDay = secondsOfDay,
        unixTime = unixTime,
        timezoneOffsetSeconds = state.timezoneOffsetSeconds,
        timezone = Config.Location.timezone,
        mode = override.active and 'manual' or 'realtime',
        override = clone(override)
    }
end

function AirOpsWeather.API.GetForecast(hours, zone)
    local resolvedZone, zoneError = normalizeZone(zone)
    if not resolvedZone then
        return nil, zoneError
    end
    zone = resolvedZone
    local cache = AirOpsWeather.GetCache()
    local requestedHours = math.max(
        1,
        math.min(tonumber(hours) or tonumber(Config.Provider.forecastHours) or 12, 12)
    )
    local cutoff = os.time() + (requestedHours * 3600)
    local result = {}

    for _, entry in ipairs(cache.timeline or {}) do
        if entry.at <= cutoff then
            result[#result + 1] = clone(entry)
        end
    end

    return result
end

function AirOpsWeather.API.GetState(zone)
    local resolvedZone, zoneError = normalizeZone(zone)
    if not resolvedZone then
        return nil, zoneError
    end
    zone = resolvedZone
    local state = AirOpsWeather.PublicState()
    state.apiVersion = AirOpsWeather.APIVersion
    state.zone = zone
    state.profile = AirOpsWeather.API.GetWeatherProfile(zone)
    state.time = AirOpsWeather.API.GetTime(zone)
    state.forecast = AirOpsWeather.API.GetForecast(nil, zone)
    state.flight = clone(state.profile.flight)
    state.warnings = clone(state.profile.warnings)
    return state
end

local VOLATILE_SIGNATURE_KEYS = {
    checkedAt = true,
    evaluatedAt = true,
    generatedAt = true,
    secondsFromNow = true,
    secondsUntilNextPoll = true,
    timestamp = true,
    unixTime = true
}

local function stableValue(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return '<cycle>'
    end

    seen[value] = true
    local copy = {}

    for key, item in pairs(value) do
        if not VOLATILE_SIGNATURE_KEYS[tostring(key)] then
            copy[key] = stableValue(item, seen)
        end
    end

    seen[value] = nil
    return copy
end

local function signature(value)
    local ok, encoded = pcall(json.encode, stableValue(value))
    return ok and encoded or tostring(value)
end

function AirOpsWeather.API.EmitChanges(force)
    if not Config.API.enabled or not Config.API.emitEvents then
        return
    end

    local state = AirOpsWeather.API.GetState()
    local profile = state.profile
    local forecast = state.forecast
    local warnings = state.warnings

    local values = {
        state = state,
        profile = profile,
        forecast = forecast,
        warnings = warnings
    }

    for key, value in pairs(values) do
        local currentSignature = signature(value)

        if force or currentSignature ~= previousSignatures[key] then
            previousSignatures[key] = currentSignature

            if key == 'state' then
                TriggerEvent(AirOpsWeather.Events.stateChanged, clone(value))
            elseif key == 'profile' then
                TriggerEvent(AirOpsWeather.Events.profileChanged, clone(value))
            elseif key == 'forecast' then
                TriggerEvent(AirOpsWeather.Events.forecastChanged, clone(value))
            elseif key == 'warnings' then
                TriggerEvent(AirOpsWeather.Events.warningsChanged, clone(value))
            end
        end
    end
end

exports('GetWeather', function(zone)
    return AirOpsWeather.API.GetWeatherProfile(zone)
end)

exports('GetTime', function(zone)
    return AirOpsWeather.API.GetTime(zone)
end)

exports('GetState', function(zone)
    return AirOpsWeather.API.GetState(zone)
end)

exports('GetForecast', function(hours, zone)
    return AirOpsWeather.API.GetForecast(hours, zone)
end)

exports('GetFlightConditions', function()
    return AirOpsWeather.API.GetFlightConditions()
end)

exports('GetWarnings', function()
    return AirOpsWeather.API.GetWarnings()
end)

-- Lowercase aliases preserve the style of earlier Community releases.
exports('getWeather', function(zone)
    return AirOpsWeather.API.GetWeatherProfile(zone)
end)

exports('getTime', function(zone)
    return AirOpsWeather.API.GetTime(zone)
end)

exports('getState', function(zone)
    return AirOpsWeather.API.GetState(zone)
end)

exports('getForecast', function(hours, zone)
    return AirOpsWeather.API.GetForecast(hours, zone)
end)

exports('getFlightConditions', function()
    return AirOpsWeather.API.GetFlightConditions()
end)

exports('getWarnings', function()
    return AirOpsWeather.API.GetWarnings()
end)
