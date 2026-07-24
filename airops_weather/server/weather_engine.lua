AirOpsWeather = AirOpsWeather or {}

function AirOpsWeather.ApplyWeatherCandidate(candidate, weatherClass, source, force, transitionSeconds)
    local cache = AirOpsWeather.GetCache()

    if AirOpsWeather.Override
        and AirOpsWeather.Override.IsWeatherActive
        and AirOpsWeather.Override.IsWeatherActive()
        and source ~= 'manual override' then
        AirOpsWeather.Debug(
            'Candidate %s from %s stored in forecast data but suppressed by manual override.',
            candidate,
            source or 'unknown'
        )
        return false
    end

    if not force and not AirOpsWeather.CanChangeWeather(candidate) then
        cache.weatherClass = weatherClass or cache.weatherClass
        AirOpsWeather.Debug(
            'Candidate %s from %s suppressed; keeping %s.',
            candidate,
            source or 'unknown',
            cache.currentWeather
        )
        return false
    end

    local oldWeather = cache.currentWeather
    AirOpsWeather.SetWeather(candidate, weatherClass, transitionSeconds)

    if oldWeather ~= candidate then
        AirOpsWeather.Info(
            'Weather changed: %s -> %s (%s)',
            oldWeather,
            candidate,
            source or 'unknown'
        )
        TriggerEvent(AirOpsWeather.Events.weatherChanged, oldWeather, candidate, source)
    end

    if AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.IsNaturalDisastersEnabled
        and AirOpsWeather.Integrations.IsNaturalDisastersEnabled() then
        AirOpsWeather.Integrations.ApplyNaturalDisastersWeather(candidate, false)
    end

    return oldWeather ~= candidate
end

function AirOpsWeather.ProcessProviderPayload(payload)
    if type(payload) ~= 'table' or type(payload.current) ~= 'table' then
        return false, 'invalid provider payload'
    end

    local candidate, weatherClass = AirOpsWeather.MapWeather(payload.current)
    AirOpsWeather.SetSuccessfulFetch(payload)
    AirOpsWeather.ApplyWeatherCandidate(candidate, weatherClass, 'current observation', false)

    if Config.Forecast and Config.Forecast.enabled then
        AirOpsWeather.BuildForecastTimeline(payload.forecast)
    else
        AirOpsWeather.SetTimeline({})
    end

    return true
end

function AirOpsWeather.BroadcastState(target)
    TriggerClientEvent(
        AirOpsWeather.Events.syncState,
        target or -1,
        AirOpsWeather.PublicState()
    )
end
