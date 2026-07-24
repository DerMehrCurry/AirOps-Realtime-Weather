local AirOps = exports['airops_weather']:GetSDK(1)

local listenerId = AirOps:Subscribe('weatherChanged', function(change)
    print(('[AirOps Example] %s -> %s'):format(
        tostring(change.previous),
        tostring(change.current)
    ))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        AirOps:Unsubscribe(listenerId)
    end
end)
