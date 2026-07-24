AirOpsWeather = AirOpsWeather or {}
local state={serverUnixTime=0,timezoneOffsetSeconds=0,receivedAt=0}
function AirOpsWeather.SetTimeState(data) state.serverUnixTime=tonumber(data.serverUnixTime) or 0 state.timezoneOffsetSeconds=tonumber(data.timezoneOffsetSeconds) or 0 state.receivedAt=GetGameTimer() end
local function clock() local elapsed=math.floor((GetGameTimer()-state.receivedAt)/1000) local epoch=state.serverUnixTime+state.timezoneOffsetSeconds+elapsed local day=epoch%86400 return math.floor(day/3600),math.floor((day%3600)/60),day%60 end
CreateThread(function() while true do if Config.Time.enabled and state.serverUnixTime>0 then local h,m,s=clock() NetworkOverrideClockTime(h,m,s) end Wait(Config.Time.clientCorrectionIntervalSeconds*1000) end end)
