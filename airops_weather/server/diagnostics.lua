AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Diagnostics = AirOpsWeather.Diagnostics or {}

local previousHealthStatus = nil

local function clone(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

local function configurationSnapshot()
    if not Config.Diagnostics.exposeConfigurationSnapshot then
        return nil
    end

    return {
        location = clone(Config.Location),
        provider = clone(Config.Provider),
        forecast = {
            enabled = Config.Forecast.enabled,
            flexibleTransitions = Config.Forecast.flexibleTransitions,
            maximumOffsetMinutes = Config.Forecast.maximumOffsetMinutes,
            transitionStepMinutes = Config.Forecast.transitionStepMinutes
        },
        logging = {
            level = Config.Logging.level,
            suppressRepeatedMessages = Config.Logging.suppressRepeatedMessages
        },
        integrations = {
            naturalDisasters = {
                enabled = Config.Integrations.naturalDisasters.enabled,
                resourceName = Config.Integrations.naturalDisasters.resourceName,
                delegateWeather = Config.Integrations.naturalDisasters.delegateWeather
            }
        }
    }
end

function AirOpsWeather.Diagnostics.GetIntegrations()
    local naturalDisasters = AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.GetNaturalDisastersState
        and AirOpsWeather.Integrations.GetNaturalDisastersState()
        or {
            available = false,
            externalControl = false,
            controller = nil
        }

    naturalDisasters.resourceName =
        Config.Integrations.naturalDisasters.resourceName

    return {
        naturalDisasters = clone(naturalDisasters)
    }
end

function AirOpsWeather.Diagnostics.GetHealth()
    local cache = AirOpsWeather.GetCache()
    local cacheHealth = AirOpsWeather.CheckCacheHealth()
    local scheduler = AirOpsWeather.GetSchedulerState
        and AirOpsWeather.GetSchedulerState()
        or {}
    local validation = AirOpsWeather.Validation.GetResult()
    local integrations = AirOpsWeather.Diagnostics.GetIntegrations()
    local issues = {}
    local status = 'HEALTHY'

    local function issue(code, severity, message)
        issues[#issues + 1] = {
            code = code,
            severity = severity,
            message = message
        }

        if severity == 'critical' then
            status = 'UNHEALTHY'
        elseif status == 'HEALTHY' then
            status = 'DEGRADED'
        end
    end

    if not validation.valid then
        issue(
            'INVALID_CONFIGURATION',
            'critical',
            'Configuration validation contains errors.'
        )
    end

    if scheduler.providerUnavailable then
        issue(
            'PROVIDER_UNAVAILABLE',
            cache.valid and 'warning' or 'critical',
            scheduler.lastProviderError or 'Provider unavailable.'
        )
    end

    if cacheHealth.stale then
        issue(
            'STALE_CACHE',
            cache.valid and 'warning' or 'critical',
            'Weather cache is stale.'
        )
    end

    if not cache.valid then
        issue(
            'NO_VALID_WEATHER_DATA',
            'critical',
            'No valid provider response has been cached.'
        )
    end

    if Config.Integrations.naturalDisasters.enabled
        and not integrations.naturalDisasters.available then
        issue(
            'OPTIONAL_INTEGRATION_UNAVAILABLE',
            'warning',
            'Natural Disasters is configured but currently unavailable; standalone fallback is active.'
        )
    end

    local health = {
        status = status,
        checkedAt = os.time(),
        provider = {
            name = AirOpsWeather.Providers.GetActiveName()
                or Config.Provider.name,
            registered = AirOpsWeather.Providers.List(),
            available = not scheduler.providerUnavailable,
            lastError = scheduler.lastProviderError,
            lastSuccessAt = cache.fetchedAt,
            consecutiveFailures = cache.failureCount
        },
        cache = {
            valid = cache.valid,
            stale = cacheHealth.stale,
            ageSeconds = cacheHealth.ageSeconds
        },
        scheduler = {
            requestActive = scheduler.requestActive or false,
            nextPollAt = cache.nextPollAt,
            secondsUntilNextPoll = cache.nextPollAt > 0
                and math.max(0, cache.nextPollAt - os.time())
                or -1
        },
        configuration = {
            valid = validation.valid,
            errors = #validation.errors,
            warnings = #validation.warnings
        },
        integrations = integrations,
        issues = issues
    }

    if previousHealthStatus and previousHealthStatus ~= status then
        TriggerEvent(
            AirOpsWeather.Events.healthChanged,
            previousHealthStatus,
            status,
            clone(health)
        )
    end

    previousHealthStatus = status
    return health
end

function AirOpsWeather.Diagnostics.GetForecast()
    local cache = AirOpsWeather.GetCache()
    local entries = {}

    for index, entry in ipairs(cache.timeline or {}) do
        entries[#entries + 1] = {
            index = index,
            at = entry.at,
            secondsFromNow = math.max(0, entry.at - os.time()),
            weather = entry.weather,
            class = entry.class,
            intermediate = entry.intermediate == true,
            targetWeather = entry.targetWeather,
            providerTime = entry.providerTime,
            temperature = entry.temperature,
            precipitation = entry.precipitation,
            visibility = entry.visibility,
            windSpeed = entry.windSpeed
        }
    end

    return {
        generatedAt = os.time(),
        generation = cache.timelineGeneration,
        count = #entries,
        entries = entries
    }
end

function AirOpsWeather.Diagnostics.GetDiagnostics()
    return {
        version = AirOpsWeather.Version,
        apiVersion = AirOpsWeather.APIVersion,
        generatedAt = os.time(),
        health = AirOpsWeather.Diagnostics.GetHealth(),
        state = AirOpsWeather.API.GetState(),
        metrics = AirOpsWeather.Metrics.Get(),
        integrationMetrics = AirOpsWeather.IntegrationMetrics.Get(),
        forecast = AirOpsWeather.Diagnostics.GetForecast(),
        integrations = AirOpsWeather.Diagnostics.GetIntegrations(),
        validation = clone(AirOpsWeather.Validation.GetResult()),
        configuration = configurationSnapshot()
    }
end

exports('GetHealth', function()
    return AirOpsWeather.Diagnostics.GetHealth()
end)

exports('GetDiagnostics', function()
    return AirOpsWeather.Diagnostics.GetDiagnostics()
end)

exports('GetIntegrations', function()
    return AirOpsWeather.Diagnostics.GetIntegrations()
end)

exports('GetForecastDiagnostics', function()
    return AirOpsWeather.Diagnostics.GetForecast()
end)

exports('getHealth', function()
    return AirOpsWeather.Diagnostics.GetHealth()
end)

exports('getDiagnostics', function()
    return AirOpsWeather.Diagnostics.GetDiagnostics()
end)

CreateThread(function()
    while true do
        Wait(60000)

        if Config.Diagnostics.enabled then
            AirOpsWeather.Diagnostics.GetHealth()
        end
    end
end)
