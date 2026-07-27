local AirOps = exports['airops_weather']:GetSDK(1)

RegisterNetEvent('scoreboard:requestWeather', function()
    local source = source
    TriggerClientEvent(
        'scoreboard:updateWeather',
        source,
        AirOps:GetWeather()
    )
end)
