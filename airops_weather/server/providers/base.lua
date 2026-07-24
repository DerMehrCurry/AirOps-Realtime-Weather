AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Providers = AirOpsWeather.Providers or {}

local registry = {}
local activeProviderName = nil

local function normalizeName(name)
    return string.lower(tostring(name or ''))
end

local function validateDefinition(definition)
    if type(definition) ~= 'table' then
        return false, 'provider definition must be a table'
    end

    if type(definition.fetch) ~= 'function' then
        return false, 'provider definition requires a fetch(callback) function'
    end

    return true
end

function AirOpsWeather.Providers.Register(name, definition)
    name = normalizeName(name)

    if name == '' then
        return false, 'provider name must not be empty'
    end

    local valid, errorMessage = validateDefinition(definition)
    if not valid then
        return false, errorMessage
    end

    definition.name = name
    definition.displayName = definition.displayName or name
    definition.version = definition.version or 1

    registry[name] = definition
    AirOpsWeather.Debug(
        'Registered provider %s (interface v%s).',
        name,
        tostring(definition.version)
    )

    return true
end

function AirOpsWeather.Providers.Get(name)
    return registry[normalizeName(name)]
end

function AirOpsWeather.Providers.Exists(name)
    return AirOpsWeather.Providers.Get(name) ~= nil
end

function AirOpsWeather.Providers.GetActive()
    local configured = normalizeName(
        Config.Provider and Config.Provider.name or 'openmeteo'
    )

    local provider = AirOpsWeather.Providers.Get(configured)

    if provider then
        activeProviderName = configured
    end

    return provider
end

function AirOpsWeather.Providers.GetActiveName()
    local provider = AirOpsWeather.Providers.GetActive()
    return provider and provider.name or activeProviderName
end

function AirOpsWeather.Providers.Fetch(callback)
    local provider = AirOpsWeather.Providers.GetActive()

    if not provider then
        callback(
            false,
            nil,
            ('unknown provider: %s'):format(
                tostring(Config.Provider and Config.Provider.name)
            )
        )
        return false
    end

    local completed = false

    local function finish(success, payload, errorMessage)
        if completed then
            AirOpsWeather.Warn(
                'Provider %s attempted to complete a request more than once.',
                provider.name
            )
            return
        end

        completed = true
        callback(success == true, payload, errorMessage)
    end

    local ok, result = pcall(provider.fetch, finish)

    if not ok then
        finish(
            false,
            nil,
            ('provider %s raised an error: %s')
                :format(provider.name, tostring(result))
        )
        return false
    end

    return result ~= false
end

function AirOpsWeather.Providers.List()
    local providers = {}

    for name, provider in pairs(registry) do
        providers[#providers + 1] = {
            name = name,
            displayName = provider.displayName,
            version = provider.version,
            description = provider.description,
            active = name == normalizeName(
                Config.Provider and Config.Provider.name
            )
        }
    end

    table.sort(providers, function(left, right)
        return left.name < right.name
    end)

    return providers
end

exports('GetRegisteredProviders', function()
    return AirOpsWeather.Providers.List()
end)
