AirOpsWeather = AirOpsWeather or {}
local state={currentWeather=nil,windSpeed=0.0,windDirection=0.0}
local function wind(data) if not Config.Weather.enableWind then SetWindSpeed(0.0) return end SetWindSpeed(math.min((tonumber(data.windSpeed) or 0.0)/80.0,1.0)) SetWindDirection((tonumber(data.windDirection) or 0.0)*math.pi/180.0) end
function AirOpsWeather.ApplyWeatherState(data,immediate)
    if not Config.Weather.enabled then return end
    local nextWeather=tostring(data.currentWeather or Config.Weather.fallback)
    if immediate or not state.currentWeather then SetWeatherTypeNowPersist(nextWeather) SetWeatherTypePersist(nextWeather) SetOverrideWeather(nextWeather) elseif nextWeather~=state.currentWeather then SetWeatherTypeOvertimePersist(nextWeather,tonumber(data.transitionSeconds) or 180.0) end
    state.currentWeather=nextWeather state.windSpeed=tonumber(data.windSpeed) or 0.0 state.windDirection=tonumber(data.windDirection) or 0.0 wind(data)
end
CreateThread(function() while true do if Config.Weather.enabled and state.currentWeather then SetWeatherTypePersist(state.currentWeather) SetOverrideWeather(state.currentWeather) end Wait(30000) end end)
exports('getCurrentWeather',function() return state.currentWeather end)
exports('getWind',function() return {speed=state.windSpeed,direction=state.windDirection} end)
