AirOpsWeather = AirOpsWeather or {}

local weatherState = {
    currentWeather = nil,
    windSpeed = 0.0,
    windDirection = 0.0
}

local function naturalDisastersDelegationEnabled()
    local settings = Config.Integrations
        and Config.Integrations.naturalDisasters

    if not settings
        or not settings.enabled
        or not settings.delegateWeather then
        return false
    end

    return GetResourceState(settings.resourceName) == 'started'
end

local function degreesToRadians(degrees)
    return degrees * math.pi / 180.0
end

local function applyWind(state)
    if not Config.Weather.enableWind or naturalDisastersDelegationEnabled() then
        return
    end

    local normalizedSpeed = math.min((tonumber(state.windSpeed) or 0.0) / 80.0, 1.0)
    SetWindSpeed(normalizedSpeed)
    SetWindDirection(degreesToRadians(tonumber(state.windDirection) or 0.0))
end

function AirOpsWeather.ApplyWeatherState(state, immediate)
    if not Config.Weather.enabled then
        return
    end

    local nextWeather = tostring(state.currentWeather or Config.Weather.fallback)
    weatherState.currentWeather = nextWeather
    weatherState.windSpeed = tonumber(state.windSpeed) or 0.0
    weatherState.windDirection = tonumber(state.windDirection) or 0.0

    -- Natural Disasters is the sole client weather synchronizer in integration mode.
    if naturalDisastersDelegationEnabled() then
        return
    end

    if immediate then
        SetWeatherTypeNowPersist(nextWeather)
        SetWeatherTypePersist(nextWeather)
        SetOverrideWeather(nextWeather)
    else
        SetWeatherTypeOvertimePersist(
            nextWeather,
            tonumber(state.transitionSeconds) or 180.0
        )
    end

    applyWind(state)
end

CreateThread(function()
    while true do
        if Config.Weather.enabled
            and weatherState.currentWeather
            and not naturalDisastersDelegationEnabled() then
            SetWeatherTypePersist(weatherState.currentWeather)
            SetOverrideWeather(weatherState.currentWeather)
        end

        Wait(tonumber(Config.Performance.clientWeatherReinforcementMilliseconds) or 60000)
    end
end)

exports('getCurrentWeather', function()
    return weatherState.currentWeather
end)

exports('getWind', function()
    return {
        speed = weatherState.windSpeed,
        direction = weatherState.windDirection
    }
end)
