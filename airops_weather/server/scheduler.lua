AirOpsWeather = AirOpsWeather or {}
local active=false
local function interval(class) if class=='stable' then return Config.AdaptivePolling.stableSeconds elseif class=='changing' then return Config.AdaptivePolling.changingSeconds elseif class=='precipitation' then return Config.AdaptivePolling.precipitationSeconds elseif class=='severe' then return Config.AdaptivePolling.severeSeconds end return Config.AdaptivePolling.normalSeconds end
local function retry(count) return math.min(Config.Retry.initialSeconds*(Config.Retry.multiplier^math.max(0,count-1)),Config.Retry.maximumSeconds) end
function AirOpsWeather.ScheduleNextUpdate(seconds) local delay=math.max(30,math.floor(seconds)) AirOpsWeather.SetNextPoll(os.time()+delay) SetTimeout(delay*1000,function() AirOpsWeather.UpdateWeather() end) AirOpsWeather.Debug('Next request in %d seconds.',delay) end
function AirOpsWeather.UpdateWeather()
    if active then return false end active=true
    local provider=string.lower(Config.Provider.name or 'openmeteo')=='openmeteo' and AirOpsWeather.Providers.OpenMeteo or nil
    if not provider then active=false AirOpsWeather.Warn('Unknown provider: %s',Config.Provider.name) return false end
    provider(function(success,payload,err)
        active=false local cache=AirOpsWeather.GetCache()
        if not success then local n=AirOpsWeather.RegisterFailure() local wait=retry(n) AirOpsWeather.Warn('Weather request failed (%d): %s. Retry in %d seconds.',n,err or 'unknown',wait) AirOpsWeather.ScheduleNextUpdate(wait) return end
        local ok,processError=AirOpsWeather.ProcessProviderPayload(payload)
        if not ok then local n=AirOpsWeather.RegisterFailure() local wait=retry(n) AirOpsWeather.Warn('Response processing failed: %s.',processError or 'unknown') AirOpsWeather.ScheduleNextUpdate(wait) return end
        AirOpsWeather.BroadcastState(-1) AirOpsWeather.ScheduleNextUpdate(interval(cache.weatherClass))
    end)
    return true
end
