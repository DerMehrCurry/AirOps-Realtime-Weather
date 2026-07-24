AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Validation = AirOpsWeather.Validation or {}

local lastResult = {
    valid = false,
    errors = {},
    warnings = {},
    checkedAt = 0
}

local function add(target, code, message)
    target[#target + 1] = {
        code = code,
        message = message
    }
end

local function numberInRange(value, minimum, maximum)
    value = tonumber(value)
    return value and value >= minimum and value <= maximum
end

local function positive(value)
    value = tonumber(value)
    return value and value > 0
end

local function validateAscending(values, names, errors)
    for index = 2, #values do
        if tonumber(values[index]) <= tonumber(values[index - 1]) then
            add(
                errors,
                'INVALID_THRESHOLD_ORDER',
                ('%s must be greater than %s.')
                    :format(names[index], names[index - 1])
            )
        end
    end
end

function AirOpsWeather.Validation.Run()
    local errors = {}
    local warnings = {}

    if not Config.Location or not numberInRange(Config.Location.latitude, -90, 90) then
        add(errors, 'INVALID_LATITUDE', 'Config.Location.latitude must be between -90 and 90.')
    end

    if not Config.Location or not numberInRange(Config.Location.longitude, -180, 180) then
        add(errors, 'INVALID_LONGITUDE', 'Config.Location.longitude must be between -180 and 180.')
    end

    if not Config.Location or tostring(Config.Location.name or '') == '' then
        add(errors, 'MISSING_LOCATION_NAME', 'Config.Location.name must not be empty.')
    end

    local providerName = string.lower(
        tostring(Config.Provider and Config.Provider.name or '')
    )

    if providerName == '' then
        add(errors, 'MISSING_PROVIDER', 'Config.Provider.name must not be empty.')
    elseif not AirOpsWeather.Providers.Exists(providerName) then
        add(
            errors,
            'UNSUPPORTED_PROVIDER',
            ('Provider %s is not registered.'):format(providerName)
        )
    end

    local forecastHours = tonumber(Config.Provider and Config.Provider.forecastHours)
    if not forecastHours or forecastHours < 1 or forecastHours > 12 then
        add(errors, 'INVALID_FORECAST_HOURS', 'Config.Provider.forecastHours must be between 1 and 12.')
    end

    for key, value in pairs(Config.AdaptivePolling or {}) do
        if not positive(value) then
            add(errors, 'INVALID_POLL_INTERVAL', ('Config.AdaptivePolling.%s must be positive.'):format(key))
        elseif tonumber(value) < 30 then
            add(warnings, 'LOW_POLL_INTERVAL', ('Config.AdaptivePolling.%s is below 30 seconds.'):format(key))
        end
    end

    if not positive(Config.Retry and Config.Retry.initialSeconds)
        or not positive(Config.Retry and Config.Retry.maximumSeconds)
        or not positive(Config.Retry and Config.Retry.requestTimeoutSeconds) then
        add(errors, 'INVALID_RETRY_CONFIGURATION', 'Retry and timeout values must be positive.')
    end

    if tonumber(Config.Retry and Config.Retry.maximumSeconds or 0)
        < tonumber(Config.Retry and Config.Retry.initialSeconds or 0) then
        add(errors, 'INVALID_RETRY_RANGE', 'Retry maximumSeconds must not be below initialSeconds.')
    end

    if not AirOpsWeather.ValidWeatherTypes
        or next(AirOpsWeather.ValidWeatherTypes) == nil then
        add(errors, 'MISSING_WEATHER_MAPPING', 'No supported GTA weather mapping is available.')
    end

    local warningConfig = Config.API and Config.API.warnings or {}
    if tonumber(warningConfig.severeWindKmh or 0)
        <= tonumber(warningConfig.strongWindKmh or 0) then
        add(errors, 'INVALID_WARNING_WIND_THRESHOLDS', 'severeWindKmh must exceed strongWindKmh.')
    end

    if tonumber(warningConfig.criticalVisibilityMeters or 0)
        >= tonumber(warningConfig.lowVisibilityMeters or 0) then
        add(errors, 'INVALID_VISIBILITY_THRESHOLDS', 'criticalVisibilityMeters must be lower than lowVisibilityMeters.')
    end

    if tonumber(warningConfig.extremePrecipitationMm or 0)
        <= tonumber(warningConfig.heavyPrecipitationMm or 0) then
        add(errors, 'INVALID_PRECIPITATION_THRESHOLDS', 'extremePrecipitationMm must exceed heavyPrecipitationMm.')
    end

    local flight = Config.API and Config.API.flight or {}
    validateAscending(
        {
            flight.yellowWindKmh or 0,
            flight.orangeWindKmh or 0,
            flight.redWindKmh or 0
        },
        { 'yellowWindKmh', 'orangeWindKmh', 'redWindKmh' },
        errors
    )
    validateAscending(
        {
            flight.yellowGustKmh or 0,
            flight.orangeGustKmh or 0,
            flight.redGustKmh or 0
        },
        { 'yellowGustKmh', 'orangeGustKmh', 'redGustKmh' },
        errors
    )

    if tonumber(flight.redVisibilityMeters or 0)
        >= tonumber(flight.orangeVisibilityMeters or 0)
        or tonumber(flight.orangeVisibilityMeters or 0)
        >= tonumber(flight.yellowVisibilityMeters or 0) then
        add(errors, 'INVALID_FLIGHT_VISIBILITY_ORDER', 'Flight visibility thresholds must descend from yellow to red.')
    end

    local integration = Config.Integrations
        and Config.Integrations.naturalDisasters
        or nil

    if integration and integration.enabled
        and tostring(integration.resourceName or '') == '' then
        add(errors, 'MISSING_INTEGRATION_RESOURCE', 'Natural Disasters resourceName must not be empty.')
    end

    if Config.General and Config.General.debug
        and Config.Logging
        and string.upper(tostring(Config.Logging.level or 'INFO')) == 'INFO' then
        add(
            warnings,
            'LEGACY_DEBUG_IGNORED',
            'Config.General.debug is enabled, but Config.Logging.level=INFO takes precedence.'
        )
    end

    lastResult = {
        valid = #errors == 0,
        errors = errors,
        warnings = warnings,
        checkedAt = os.time()
    }

    AirOpsWeather.Info(
        'Configuration validation completed: %d error(s), %d warning(s).',
        #errors,
        #warnings
    )

    for _, item in ipairs(errors) do
        AirOpsWeather.Error('%s: %s', item.code, item.message)
    end

    for _, item in ipairs(warnings) do
        AirOpsWeather.Warn('%s: %s', item.code, item.message)
    end

    return lastResult.valid, lastResult
end

function AirOpsWeather.Validation.GetResult()
    return lastResult
end

exports('ValidateConfiguration', function()
    return AirOpsWeather.Validation.Run()
end)
