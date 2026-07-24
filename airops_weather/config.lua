Config = {}

Config.General = {
    locale = 'de',
    debug = false
}

Config.Location = {
    name = 'Lüneburg',
    latitude = 53.2464,
    longitude = 10.4115,
    timezone = 'Europe/Berlin'
}

Config.Provider = {
    name = 'openmeteo',
    forecastHours = 6
}

Config.Time = {
    enabled = true,
    syncIntervalSeconds = 300,
    clientCorrectionIntervalSeconds = 10
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
        monitorIntervalMilliseconds = 1000,
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
    maximumSeconds = 900
}
