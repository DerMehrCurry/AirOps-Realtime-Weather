AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.SelfTest = AirOpsWeather.SelfTest or {}

local checks = {}

local function add(name, callback)
    checks[#checks + 1] = {
        name = name,
        callback = callback
    }
end

local function result(name, success, details)
    return {
        name = name,
        success = success == true,
        details = details
    }
end

add('configuration', function()
    local validation = AirOpsWeather.Validation.Run()
    return #validation.errors == 0,
        ('errors=%d warnings=%d'):format(
            #validation.errors,
            #validation.warnings
        )
end)

add('provider', function()
    local provider = AirOpsWeather.Providers.GetActive()
    return provider ~= nil,
        provider and provider.name or 'no active provider'
end)

add('default-zone', function()
    local zone, errorMessage = AirOpsWeather.Zones.GetDefault()
    return zone ~= nil, zone or errorMessage
end)

add('sdk-v1', function()
    local sdk, errorMessage = AirOpsWeather.SDK.Get(1)
    return sdk ~= nil, sdk and 'registered' or errorMessage
end)

add('json-schema', function()
    local schema = AirOpsWeather.JSON.GetSchema()
    return type(schema) == 'table'
        and schema.schemaVersion == 1,
        schema and schema.schema or 'missing schema'
end)

add('integration-bus', function()
    return type(AirOpsWeather.Integrations.Publish) == 'function',
        'publish function available'
end)

add('diagnostics', function()
    local diagnostics = AirOpsWeather.Diagnostics.GetDiagnostics()
    return type(diagnostics) == 'table',
        diagnostics and 'available' or 'unavailable'
end)

function AirOpsWeather.SelfTest.Run()
    local report = {
        version = AirOpsWeather.Version,
        timestamp = os.time(),
        success = true,
        passed = 0,
        failed = 0,
        checks = {}
    }

    for _, check in ipairs(checks) do
        local ok, success, details = pcall(check.callback)

        if not ok then
            success = false
            details = tostring(success)
        end

        local checkResult = result(
            check.name,
            ok and success == true,
            details
        )

        report.checks[#report.checks + 1] = checkResult

        if checkResult.success then
            report.passed = report.passed + 1
        else
            report.failed = report.failed + 1
            report.success = false
        end
    end

    TriggerEvent(AirOpsWeather.Events.selfTestCompleted, report)
    AirOpsWeather.Integrations.Publish('selfTestCompleted', report)

    return report
end

exports('RunSelfTest', function()
    return AirOpsWeather.SelfTest.Run()
end)
