local AirOps = exports['airops_weather']:GetSDK(1)

RegisterNetEvent('phone:requestWeather', function()
    local source = source
    TriggerClientEvent(
        'phone:receiveWeather',
        source,
        AirOps:GetJSONDocument()
    )
end)
