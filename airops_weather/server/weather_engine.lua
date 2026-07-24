AirOpsWeather = AirOpsWeather or {}

function AirOpsWeather.ApplyWeatherCandidate(
    candidate,
    weatherClass,
    source,
    force,
    transitionSeconds
)
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
        AirOpsWeather.Metrics.Increment('weatherChanges')
        AirOpsWeather.Info(
            'Weather changed: %s -> %s (%s)',
            oldWeather,
            candidate,
            source or 'unknown'
        )
        TriggerEvent(
            AirOpsWeather.Events.weatherChanged,
            oldWeather,
            candidate,
            source
        )

        if AirOpsWeather.API and AirOpsWeather.API.EmitChanges then
            AirOpsWeather.API.EmitChanges(false)
        end
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
    local changed = AirOpsWeather.ApplyWeatherCandidate(
        candidate,
        weatherClass,
        'current observation',
        false
    )

    if Config.Forecast and Config.Forecast.enabled then
        AirOpsWeather.BuildForecastTimeline(payload.forecast)
    else
        AirOpsWeather.SetTimeline({})
    end

    return true, changed
end

function AirOpsWeather.BroadcastState(target, force)
    target = target or -1

    if target == -1 and not AirOpsWeather.ShouldBroadcast(force) then
        AirOpsWeather.Metrics.RecordBroadcast(target, true)
        AirOpsWeather.Debug('Global state broadcast suppressed; no relevant change.')
        return false
    end

    TriggerClientEvent(
        AirOpsWeather.Events.syncState,
        target,
        AirOpsWeather.PublicState()
    )

    AirOpsWeather.Metrics.RecordBroadcast(target, false)

    if target == -1 then
        AirOpsWeather.MarkBroadcastSnapshot()

        if AirOpsWeather.API and AirOpsWeather.API.EmitChanges then
            AirOpsWeather.API.EmitChanges(false)
        end
    end

    return true
end
