AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.JSON = AirOpsWeather.JSON or {}

local lastSignature = nil
local lastDocument = nil

local VOLATILE_SIGNATURE_KEYS = {
    checkedAt = true,
    evaluatedAt = true,
    generatedAt = true,
    secondsFromNow = true,
    secondsUntilNextPoll = true,
    timestamp = true,
    unixTime = true
}

local function cloneStable(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return '<cycle>'
    end

    seen[value] = true
    local copy = {}

    for key, item in pairs(value) do
        if not VOLATILE_SIGNATURE_KEYS[tostring(key)] then
            copy[key] = cloneStable(item, seen)
        end
    end

    seen[value] = nil
    return copy
end

local function buildDocument(zone)
    local resolvedZone, zoneError = AirOpsWeather.Zones.Resolve(zone)
    if not resolvedZone then
        return nil, zoneError
    end

    local weather, errorMessage =
        AirOpsWeather.API.GetWeatherProfile(resolvedZone)

    if not weather then
        return nil, errorMessage
    end

    local forecast = {}
    if Config.JSON.includeForecast then
        forecast = AirOpsWeather.API.GetForecast(nil, resolvedZone) or {}
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
        zone = resolvedZone,
        zones = AirOpsWeather.Zones.List(),
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

local function prettyPrint(payload, indentSize)
    indentSize = math.max(1, tonumber(indentSize) or 2)
    local output = {}
    local depth = 0
    local inString = false
    local escaped = false

    local function newline()
        output[#output + 1] = '\n'
        output[#output + 1] = string.rep(' ', depth * indentSize)
    end

    for index = 1, #payload do
        local character = payload:sub(index, index)

        if inString then
            output[#output + 1] = character

            if escaped then
                escaped = false
            elseif character == '\\' then
                escaped = true
            elseif character == '"' then
                inString = false
            end
        elseif character == '"' then
            inString = true
            output[#output + 1] = character
        elseif character == '{' or character == '[' then
            output[#output + 1] = character
            depth = depth + 1
            newline()
        elseif character == '}' or character == ']' then
            depth = math.max(0, depth - 1)
            newline()
            output[#output + 1] = character
        elseif character == ',' then
            output[#output + 1] = character
            newline()
        elseif character == ':' then
            output[#output + 1] = ': '
        elseif not character:match('%s') then
            output[#output + 1] = character
        end
    end

    return table.concat(output)
end

local function encode(document, pretty)
    local payload = json.encode(document)

    if pretty then
        return prettyPrint(payload, Config.JSON.prettyIndent)
    end

    return payload
end

local function signature(document)
    local ok, encoded = pcall(json.encode, cloneStable(document))
    return ok and encoded or tostring(document)
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

    local currentSignature = signature(document)

    if currentSignature ~= lastSignature then
        lastSignature = currentSignature
        lastDocument = document
        TriggerEvent(AirOpsWeather.Events.jsonUpdated, document)
    end

    AirOpsWeather.IntegrationMetrics.Increment(
        pretty and 'jsonPrettyExports' or 'jsonExports'
    )

    return encode(document, pretty)
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
