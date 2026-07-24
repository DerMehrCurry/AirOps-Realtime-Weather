AirOpsWeather = AirOpsWeather or {}

local function printReport(report)
    local status = report.success and 'PASSED' or 'FAILED'

    print((
        '[AirOps Weather] Self-test %s: %d passed, %d failed'
    ):format(status, report.passed, report.failed))

    for _, check in ipairs(report.checks) do
        print((
            '  [%s] %s - %s'
        ):format(
            check.success and 'PASS' or 'FAIL',
            check.name,
            tostring(check.details or '')
        ))
    end
end

RegisterCommand(
    Config.SelfTest.command or 'airops_weather_selftest',
    function(source)
        if source ~= 0 then
            return
        end

        printReport(AirOpsWeather.SelfTest.Run())
    end,
    true
)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName()
        or not Config.SelfTest.enabled
        or not Config.SelfTest.runOnStartup then
        return
    end

    SetTimeout(
        tonumber(Config.SelfTest.startupDelayMs) or 2500,
        function()
            printReport(AirOpsWeather.SelfTest.Run())
        end
    )
end)
