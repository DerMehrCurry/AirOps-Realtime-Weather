AirOpsWeather = AirOpsWeather or {}

local function repeatValue(value, count)
    local result = {}

    for index = 1, count do
        result[index] = value
    end

    return result
end

local function buildForecast(config, hours)
    local forecast = {
        time = {},
        temperature_2m = {},
        relative_humidity_2m = {},
        surface_pressure = {},
        weather_code = {},
        precipitation = {},
        cloud_cover = {},
        visibility = {},
        wind_speed_10m = {},
        wind_direction_10m = {},
        wind_gusts_10m = {}
    }

    local now = os.time()

    for index = 1, hours do
        forecast.time[index] = os.date(
            '!%Y-%m-%dT%H:00',
            now + ((index - 1) * 3600)
        )
    end

    forecast.temperature_2m =
        repeatValue(tonumber(config.temperature) or 20, hours)
    forecast.relative_humidity_2m =
        repeatValue(tonumber(config.humidity) or 55, hours)
    forecast.surface_pressure =
        repeatValue(tonumber(config.pressure) or 1015, hours)
    forecast.weather_code =
        repeatValue(tonumber(config.weatherCode) or 0, hours)
    forecast.precipitation =
        repeatValue(tonumber(config.precipitation) or 0, hours)
    forecast.cloud_cover =
        repeatValue(tonumber(config.cloudCover) or 10, hours)
    forecast.visibility =
        repeatValue(tonumber(config.visibility) or 10000, hours)
    forecast.wind_speed_10m =
        repeatValue(tonumber(config.windSpeed) or 8, hours)
    forecast.wind_direction_10m =
        repeatValue(tonumber(config.windDirection) or 180, hours)
    forecast.wind_gusts_10m =
        repeatValue(tonumber(config.windGusts) or 12, hours)

    return forecast
end

local registered, registrationError = AirOpsWeather.Providers.Register(
    'mock',
    {
        displayName = 'Mock Provider',
        description = 'Deterministic local provider for development and tests.',
        version = 1,

        fetch = function(callback)
            local config = Config.MockProvider or {}
            local hours = math.max(
                1,
                tonumber(Config.Provider.forecastHours) or 6
            )

            callback(
                true,
                {
                    provider = 'mock',
                    timezoneOffsetSeconds = 0,
                    current = {
                        temperature = tonumber(config.temperature) or 20,
                        humidity = tonumber(config.humidity) or 55,
                        pressure = tonumber(config.pressure) or 1015,
                        precipitation =
                            tonumber(config.precipitation) or 0,
                        weatherCode = tonumber(config.weatherCode) or 0,
                        cloudCover = tonumber(config.cloudCover) or 10,
                        visibility = tonumber(config.visibility) or 10000,
                        windSpeed = tonumber(config.windSpeed) or 8,
                        windDirection =
                            tonumber(config.windDirection) or 180,
                        windGusts = tonumber(config.windGusts) or 12
                    },
                    forecast = buildForecast(config, hours)
                }
            )

            return true
        end
    }
)

if not registered then
    AirOpsWeather.Error(
        'Mock provider registration failed: %s',
        registrationError
    )
end
