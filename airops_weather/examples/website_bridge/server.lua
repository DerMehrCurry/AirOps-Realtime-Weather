local AirOps = exports['airops_weather']:GetSDK(1)

RegisterCommand('weatherjson', function(source)
    if source ~= 0 then
        return
    end

    print(AirOps:GetJSON())
end, true)
