Config = {}

Config.General = {
    locale = 'de',

    -- Kept for compatibility. Config.Logging.level takes precedence.
    debug = false
}

Config.Logging = {
    -- ERROR, WARN, INFO, DEBUG or TRACE
    level = 'INFO',

    -- Prevent repeated provider and integration errors from flooding the console.
    suppressRepeatedMessages = true,
    repeatWindowSeconds = 300,
    repeatSummaryThreshold = 2
}

Config.Diagnostics = {
    enabled = true,
    command = 'airops',
    maximumForecastEntriesInChat = 8,
    exposeConfigurationSnapshot = true
}

Config.Location = {
    name = 'Lüneburg',
    latitude = 53.2464,
    longitude = 10.4115,
    timezone = 'Europe/Berlin'
}

Config.Provider = {
    name = 'openmeteo',
    forecastHours = 12
}

Config.Forecast = {
    enabled = true,

    -- Consecutive forecast hours that map to the same GTA weather are compressed
    -- into one timeline target.
    compressIdenticalStates = true,

    -- Ignore very short forecast states when they would immediately reverse.
    minimumTimelineStateSeconds = 1800,

    -- Provider hours are forecast reference points, not hard switch times.
    flexibleTransitions = true,

    -- Deterministic offset around the provider hour. The same forecast always
    -- receives the same offset, including after a resource restart.
    maximumOffsetMinutes = 20,

    -- Time between generated intermediate states such as CLOUDS -> OVERCAST -> RAIN.
    transitionStepMinutes = 8,

    -- Keep generated entries ordered and prevent several changes firing together.
    minimumEntrySpacingSeconds = 180,
    minimumFutureSeconds = 120,

    transitionSecondsByClass = {
        stable = 240,
        normal = 300,
        changing = 360,
        precipitation = 420,
        severe = 480
    }
}

Config.Time = {
    enabled = true,

    -- Request a fresh authoritative timestamp from the server every five minutes.
    syncIntervalSeconds = 300,

    -- The GTA clock normally advances much faster than real time. AirOps pauses the
    -- native clock and applies the locally calculated real time at this interval.
    localUpdateIntervalMilliseconds = 1000
}

Config.Weather = {
    enabled = true,
    transitionSeconds = 180,
    enableWind = true,
    enableSnow = true,
    fallback = 'CLOUDS',
    minimumStateDurationSeconds = 300
}

-- Natural Disasters compatibility mode.
-- When enabled, AirOps does not set GTA weather directly. Instead it delegates the
-- real baseline weather to night_natural_disasters so only one weather synchronizer
-- controls clients. Disaster weather automatically takes ownership when detected.
Config.Integrations = {
    naturalDisasters = {
        enabled = true,
        resourceName = 'night_natural_disasters',
        delegateWeather = true,
        -- Slow checks during normal operation, faster checks only while an
        -- external disaster owns the weather.
        idleMonitorIntervalMilliseconds = 10000,
        activeMonitorIntervalMilliseconds = 2000,
        applyGraceMilliseconds = 5000,
        pauseAirOpsTime = false,
        automaticOwnershipDetection = true
    }
}

Config.AdaptivePolling = {
    stableSeconds = 1500,
    normalSeconds = 1200,
    changingSeconds = 720,
    precipitationSeconds = 480,
    severeSeconds = 300
}

Config.Retry = {
    initialSeconds = 60,
    multiplier = 2,
    maximumSeconds = 900,

    -- A request callback arriving after this watchdog is ignored.
    requestTimeoutSeconds = 20
}

Config.Performance = {
    -- Do not broadcast the full state after every provider refresh when weather,
    -- wind and temperature stayed effectively unchanged.
    suppressUnchangedBroadcasts = true,

    -- A periodic safety broadcast keeps long-running clients synchronized even
    -- when provider data remains unchanged.
    heartbeatBroadcastSeconds = 900,

    -- Changes smaller than these thresholds do not trigger a global broadcast.
    windChangeThresholdKmh = 2.0,
    windDirectionThresholdDegrees = 15.0,
    temperatureChangeThresholdCelsius = 1.0,

    -- Standalone clients reinforce the persistent weather only at this interval.
    clientWeatherReinforcementMilliseconds = 60000
}

Config.Health = {
    -- The cache remains usable during outages, but diagnostics mark it stale.
    staleCacheSeconds = 1800,
    warnWhenCacheBecomesStale = true
}


Config.API = {
    enabled = true,

    -- Emit local server events when standardized data changes.
    emitEvents = true,

    -- Client exports use the last authoritative state received from the server.
    enableClientExports = true,

    -- Values used for derived warnings and flight conditions.
    warnings = {
        strongWindKmh = 35,
        severeWindKmh = 55,
        lowVisibilityMeters = 3000,
        criticalVisibilityMeters = 1200,
        heavyPrecipitationMm = 4.0,
        extremePrecipitationMm = 8.0
    },

    flight = {
        yellowWindKmh = 30,
        orangeWindKmh = 45,
        redWindKmh = 60,
        yellowGustKmh = 40,
        orangeGustKmh = 55,
        redGustKmh = 70,
        yellowVisibilityMeters = 5000,
        orangeVisibilityMeters = 2500,
        redVisibilityMeters = 1000
    }
}

-- Manual overrides are optional and protected by the airops.weather.override ACE.
Config.Override = {
    enabled = true,
    command = 'airops',
    weatherTransitionSeconds = 180,
    allowPermanent = true,
    maximumDurationMinutes = 1440
}
