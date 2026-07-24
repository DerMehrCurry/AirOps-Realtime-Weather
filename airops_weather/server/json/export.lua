AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.JSON = AirOpsWeather.JSON or {}

local lastSignature = nil
local lastDocument = nil

local function buildDocument(zone)
    local weather, errorMessage =
        AirOpsWeather.API.GetWeatherProfile(zone)

    if not weather then
        return nil, errorMessage
    end

    local forecast = {}
    if Config.JSON.includeForecast then
        forecast = AirOpsWeather.API.GetForecast(nil, zone) or {}
    end

    local warnings = AirOpsWeather.API.GetWarnings(weather)
    local flight = AirOpsWeather.API.GetFlightConditions(weather)

    local document = {
        schema = 'airops-weather-state',
        schemaVersion = 1,
        resourceVersion = AirOpsWeather.Version,
        apiVersion = AirOpsWeather.APIVersion,
        sdkVersion = Config.SDK.defaultVersion,
        provider = AirOpsWeather.Providers.GetActiveName(),
        zone = zone or Config.SDK.defaultZone,
        timestamp = os.time(),
        weather = weather,
        forecast = forecast,
        warnings = warnings,
        flight = flight
    }

    if Config.JSON.includeHealth then
        document.health = AirOpsWeather.Diagnostics.GetHealth()
    end

    if Config.JSON.includeDiagnostics then
        document.diagnostics = AirOpsWeather.Diagnostics.GetDiagnostics()
        document.integrationMetrics =
            AirOpsWeather.IntegrationMetrics.Get()
    end

    return document
end

local function encode(document, pretty)
    if pretty and json.encode then
        -- FiveM's JSON implementation does not consistently expose a pretty
        -- formatter. The beta keeps one canonical payload and exposes the
        -- pretty export as a compatibility endpoint.
        return json.encode(document)
    end

    return json.encode(document)
end

function AirOpsWeather.JSON.GetDocument(zone)
    return buildDocument(zone)
end

function AirOpsWeather.JSON.Get(zone, pretty)
    if not Config.JSON.enabled then
        return nil, 'JSON export is disabled'
    end

    local document, errorMessage = buildDocument(zone)
    if not document then
        return nil, errorMessage
    end

    local payload = encode(document, pretty)
    local signature = payload

    if signature ~= lastSignature then
        lastSignature = signature
        lastDocument = document
        TriggerEvent(AirOpsWeather.Events.jsonUpdated, document)
        AirOpsWeather.Integrations.Publish('jsonUpdated', document)
    end

    AirOpsWeather.IntegrationMetrics.Increment(
        pretty and 'jsonPrettyExports' or 'jsonExports'
    )

    return payload
end

function AirOpsWeather.JSON.GetLastDocument()
    return lastDocument
end

exports('GetJSON', function(zone)
    return AirOpsWeather.JSON.Get(zone, false)
end)

exports('GetJSONPretty', function(zone)
    return AirOpsWeather.JSON.Get(zone, true)
end)

exports('GetJSONDocument', function(zone)
    return AirOpsWeather.JSON.GetDocument(zone)
end)

exports('GetJSONSchema', function()
    return AirOpsWeather.JSON.GetSchema()
end)
