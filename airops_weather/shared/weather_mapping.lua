AirOpsWeather = AirOpsWeather or {}

-- Supported GTA V weather types produced by the Open-Meteo mapping.
-- Validation uses this registry to confirm that a usable mapping is loaded.
AirOpsWeather.ValidWeatherTypes = AirOpsWeather.ValidWeatherTypes or {
    EXTRASUNNY = true,
    CLEAR = true,
    CLOUDS = true,
    OVERCAST = true,
    RAIN = true,
    THUNDER = true,
    FOGGY = true,
    SNOWLIGHT = true,
    BLIZZARD = true
}
local thunder={[95]=true,[96]=true,[99]=true}
local rain={[51]=true,[53]=true,[55]=true,[56]=true,[57]=true,[61]=true,[63]=true,[65]=true,[66]=true,[67]=true,[80]=true,[81]=true,[82]=true}
local snow={[71]=true,[73]=true,[75]=true,[77]=true,[85]=true,[86]=true}
local fog={[45]=true,[48]=true}

function AirOpsWeather.MapWeather(data)
    local code=tonumber(data.weatherCode) or 3
    local cloud=tonumber(data.cloudCover) or 0
    local precipitation=tonumber(data.precipitation) or 0
    local visibility=tonumber(data.visibility) or 10000
    local gusts=tonumber(data.windGusts) or 0
    if thunder[code] or (precipitation>=6.0 and gusts>=60.0) then return 'THUNDER','severe' end
    if snow[code] then
        if not Config.Weather.enableSnow then return 'RAIN','precipitation' end
        if code==75 or code==86 then return 'BLIZZARD','severe' end
        return 'SNOWLIGHT','precipitation'
    end
    if rain[code] or precipitation>=0.2 then return 'RAIN','precipitation' end
    if fog[code] or visibility<1500 then return 'FOGGY','changing' end
    if code==0 and cloud<15 then return 'EXTRASUNNY','stable' end
    if code==1 or cloud<35 then return 'CLEAR','stable' end
    if code==2 or cloud<70 then return 'CLOUDS','normal' end
    return 'OVERCAST','changing'
end
