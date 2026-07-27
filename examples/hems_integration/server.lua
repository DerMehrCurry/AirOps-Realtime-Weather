local AirOps = exports['airops_weather']:GetSDK(1)

RegisterCommand('flightstatus', function(source)
    local flight = AirOps:GetFlightConditions()

    print(('[AirOps HEMS] Flight category: %s'):format(
        tostring(flight and flight.category or 'UNKNOWN')
    ))
end, false)
