AirOpsWeather = AirOpsWeather or {}

local initialSyncCompleted = false

RegisterNetEvent(AirOpsWeather.Events.syncState, function(state)
    if type(state) ~= 'table' then
        return
    end

    if AirOpsWeather.ClientAPI and AirOpsWeather.ClientAPI.SetState then
        AirOpsWeather.ClientAPI.SetState(state)
    end

    AirOpsWeather.SetTimeState(state)
    AirOpsWeather.ApplyWeatherState(state, not initialSyncCompleted)
    TriggerEvent('airops_weather:client:stateChanged', state)
    initialSyncCompleted = true
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent(AirOpsWeather.Events.requestSync)
    end
end)

CreateThread(function()
    while true do
        Wait((tonumber(Config.Time.syncIntervalSeconds) or 300) * 1000)
        TriggerServerEvent(AirOpsWeather.Events.requestSync)
    end
end)
