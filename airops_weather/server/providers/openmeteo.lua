AirOpsWeather = AirOpsWeather or {}

local function encode(value)
    return tostring(value):gsub(
        '([^%w%-_%.~])',
        function(character)
            return string.format('%%%02X', string.byte(character))
        end
    )
end

local function buildUrl()
    local current = table.concat({
        'temperature_2m',
        'relative_humidity_2m',
        'surface_pressure',
        'precipitation',
        'weather_code',
        'cloud_cover',
        'visibility',
        'wind_speed_10m',
        'wind_direction_10m',
        'wind_gusts_10m'
    }, ',')

    local hourly = table.concat({
        'temperature_2m',
        'relative_humidity_2m',
        'surface_pressure',
        'weather_code',
        'precipitation',
        'cloud_cover',
        'visibility',
        'wind_speed_10m',
        'wind_direction_10m',
        'wind_gusts_10m'
    }, ',')

    return (
        'https://api.open-meteo.com/v1/forecast'
        .. '?latitude=%s'
        .. '&longitude=%s'
        .. '&current=%s'
        .. '&hourly=%s'
        .. '&forecast_hours=%d'
        .. '&timezone=%s'
        .. '&wind_speed_unit=kmh'
    ):format(
        encode(Config.Location.latitude),
        encode(Config.Location.longitude),
        encode(current),
        encode(hourly),
        tonumber(Config.Provider.forecastHours) or 6,
        encode(Config.Location.timezone)
    )
end

local function normalize(body)
    local decoded = json.decode(body)

    if type(decoded) ~= 'table' or type(decoded.current) ~= 'table' then
        return nil, 'invalid Open-Meteo response'
    end

    local current = decoded.current

    return {
        provider = 'openmeteo',
        timezoneOffsetSeconds = tonumber(decoded.utc_offset_seconds) or 0,
        current = {
            temperature = current.temperature_2m,
            humidity = current.relative_humidity_2m,
            pressure = current.surface_pressure,
            precipitation = current.precipitation,
            weatherCode = current.weather_code,
            cloudCover = current.cloud_cover,
            visibility = current.visibility,
            windSpeed = current.wind_speed_10m,
            windDirection = current.wind_direction_10m,
            windGusts = current.wind_gusts_10m
        },
        forecast = decoded.hourly or {}
    }
end

local registered, registrationError = AirOpsWeather.Providers.Register(
    'openmeteo',
    {
        displayName = 'Open-Meteo',
        description = 'Realtime and forecast weather from Open-Meteo.',
        version = 1,

        fetch = function(callback)
            PerformHttpRequest(
                buildUrl(),
                function(statusCode, body, _, requestError)
                    if statusCode ~= 200 then
                        callback(
                            false,
                            nil,
                            ('HTTP %s: %s'):format(
                                tostring(statusCode),
                                requestError or 'unknown error'
                            )
                        )
                        return
                    end

                    local ok, payload, normalizeError =
                        pcall(normalize, body)

                    if not ok then
                        callback(
                            false,
                            nil,
                            ('JSON processing failed: %s')
                                :format(tostring(payload))
                        )
                        return
                    end

                    if not payload then
                        callback(false, nil, normalizeError)
                        return
                    end

                    callback(true, payload)
                end,
                'GET',
                '',
                {
                    ['Accept'] = 'application/json',
                    ['User-Agent'] =
                        'AirOps-Realtime-Weather/' .. AirOpsWeather.Version
                }
            )

            return true
        end
    }
)

if not registered then
    AirOpsWeather.Error(
        'Open-Meteo provider registration failed: %s',
        registrationError
    )
end
