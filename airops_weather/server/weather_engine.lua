AirOpsWeather = AirOpsWeather or {}
function AirOpsWeather.ProcessProviderPayload(payload)
    if type(payload)~='table' or type(payload.current)~='table' then return false,'invalid provider payload' end
    local candidate,class=AirOpsWeather.MapWeather(payload.current)
    local cache=AirOpsWeather.GetCache()
    AirOpsWeather.SetSuccessfulFetch(payload)
    if AirOpsWeather.CanChangeWeather(candidate) then
        local old=cache.currentWeather
        AirOpsWeather.SetWeather(candidate,class)
        if old~=candidate then AirOpsWeather.Info('Weather changed: %s -> %s',old,candidate) TriggerEvent(AirOpsWeather.Events.weatherChanged,old,candidate) end
    else
        cache.weatherClass=class
        AirOpsWeather.Debug('Candidate %s suppressed; keeping %s.',candidate,cache.currentWeather)
    end
    return true
end
function AirOpsWeather.BroadcastState(target) TriggerClientEvent(AirOpsWeather.Events.syncState,target or -1,AirOpsWeather.PublicState()) end
