AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.JSON = AirOpsWeather.JSON or {}

function AirOpsWeather.JSON.GetSchema()
    return {
        schema = 'airops-weather-state',
        schemaVersion = 1,
        required = {
            'resourceVersion',
            'apiVersion',
            'sdkVersion',
            'provider',
            'zone',
            'zones',
            'timestamp',
            'weather',
            'forecast',
            'warnings',
            'flight'
        },
        optional = {
            'health',
            'diagnostics'
        }
    }
end
