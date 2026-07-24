AirOpsWeather = AirOpsWeather or {}
local initial=false
RegisterNetEvent(AirOpsWeather.Events.syncState,function(state) if type(state)~='table' then return end AirOpsWeather.SetTimeState(state) AirOpsWeather.ApplyWeatherState(state,not initial) initial=true end)
AddEventHandler('onClientResourceStart',function(name) if name==GetCurrentResourceName() then TriggerServerEvent(AirOpsWeather.Events.requestSync) end end)
CreateThread(function() while true do Wait(Config.Time.syncIntervalSeconds*1000) TriggerServerEvent(AirOpsWeather.Events.requestSync) end end)
