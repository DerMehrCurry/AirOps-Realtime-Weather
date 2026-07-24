AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Providers = AirOpsWeather.Providers or {}
local function enc(v) return tostring(v):gsub('([^%w%-_%.~])',function(c) return string.format('%%%02X',string.byte(c)) end) end
local function url()
    local current='temperature_2m,precipitation,weather_code,cloud_cover,visibility,wind_speed_10m,wind_direction_10m,wind_gusts_10m'
    local hourly='weather_code,precipitation,cloud_cover,visibility,wind_speed_10m,wind_direction_10m,wind_gusts_10m'
    return ('https://api.open-meteo.com/v1/forecast?latitude=%s&longitude=%s&current=%s&hourly=%s&forecast_hours=%d&timezone=%s&wind_speed_unit=kmh'):format(enc(Config.Location.latitude),enc(Config.Location.longitude),enc(current),enc(hourly),tonumber(Config.Provider.forecastHours) or 6,enc(Config.Location.timezone))
end
local function normalize(body)
    local d=json.decode(body)
    if type(d)~='table' or type(d.current)~='table' then return nil,'invalid Open-Meteo response' end
    local c=d.current
    return {timezoneOffsetSeconds=tonumber(d.utc_offset_seconds) or 0,current={temperature=c.temperature_2m,precipitation=c.precipitation,weatherCode=c.weather_code,cloudCover=c.cloud_cover,visibility=c.visibility,windSpeed=c.wind_speed_10m,windDirection=c.wind_direction_10m,windGusts=c.wind_gusts_10m},forecast=d.hourly or {}}
end
function AirOpsWeather.Providers.OpenMeteo(callback)
    PerformHttpRequest(url(),function(status,body,_,err)
        if status~=200 then callback(false,nil,('HTTP %s: %s'):format(status,err or 'unknown error')) return end
        local ok,payload,normalizeError=pcall(normalize,body)
        if not ok then callback(false,nil,('JSON processing failed: %s'):format(payload)) return end
        if not payload then callback(false,nil,normalizeError) return end
        callback(true,payload)
    end,'GET','',{['Accept']='application/json',['User-Agent']='AirOps-Realtime-Weather/'..AirOpsWeather.Version})
end
