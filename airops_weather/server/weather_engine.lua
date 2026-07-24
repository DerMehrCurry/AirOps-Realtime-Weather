AirOpsWeather = AirOpsWeather or {}

function AirOpsWeather.ProcessProviderPayload(payload)
    if type(payload) ~= 'table' or type(payload.current) ~= 'table' then
        return false, 'invalid provider payload'
    end

    local candidate, weatherClass = AirOpsWeather.MapWeather(payload.current)
    local cache = AirOpsWeather.GetCache()

    AirOpsWeather.SetSuccessfulFetch(payload)

    if AirOpsWeather.CanChangeWeather(candidate) then
        local oldWeather = cache.currentWeather
        AirOpsWeather.SetWeather(candidate, weatherClass)

        if oldWeather ~= candidate then
            AirOpsWeather.Info('Weather changed: %s -> %s', oldWeather, candidate)
            TriggerEvent(AirOpsWeather.Events.weatherChanged, oldWeather, candidate)
        end

        if AirOpsWeather.Integrations
            and AirOpsWeather.Integrations.IsNaturalDisastersEnabled
            and AirOpsWeather.Integrations.IsNaturalDisastersEnabled() then
            AirOpsWeather.Integrations.ApplyNaturalDisastersWeather(candidate, false)
        end
    else
        cache.weatherClass = weatherClass
        AirOpsWeather.Debug(
            'Candidate %s suppressed; keeping %s.',
            candidate,
            cache.currentWeather
        )
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
