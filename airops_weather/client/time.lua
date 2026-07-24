AirOpsWeather = AirOpsWeather or {}

local state = {
    serverUnixTime = 0,
    timezoneOffsetSeconds = 0,
    receivedAt = 0
}

function AirOpsWeather.SetTimeState(data)
    state.serverUnixTime = tonumber(data.serverUnixTime) or 0
    state.timezoneOffsetSeconds = tonumber(data.timezoneOffsetSeconds) or 0
    state.receivedAt = GetGameTimer()
end

local function getRealtimeClock()
    local elapsedSeconds = math.floor((GetGameTimer() - state.receivedAt) / 1000)
    local localEpoch = state.serverUnixTime
        + state.timezoneOffsetSeconds
        + elapsedSeconds

    local secondsOfDay = localEpoch % 86400
    local hour = math.floor(secondsOfDay / 3600)
    local minute = math.floor((secondsOfDay % 3600) / 60)
    local second = secondsOfDay % 60

    return hour, minute, second
end

local function airOpsControlsTime()
    if not Config.Time.enabled then
        return false
    end

    local integration = Config.Integrations
        and Config.Integrations.naturalDisasters

    if integration
        and integration.enabled
        and integration.pauseAirOpsTime
        and GetResourceState(integration.resourceName) == 'started' then
        return false
    end

    return true
end

CreateThread(function()
    local clockPausedByAirOps = false

    while true do
        if airOpsControlsTime() and state.serverUnixTime > 0 then
            -- GTA's native clock advances several game minutes per real minute.
            -- Pausing it prevents the visible jump between real time and +5 minutes.
            PauseClock(true)
            clockPausedByAirOps = true

            local hour, minute, second = getRealtimeClock()
            NetworkOverrideClockTime(hour, minute, second)
        elseif clockPausedByAirOps then
            PauseClock(false)
            clockPausedByAirOps = false
        end

        Wait(Config.Time.localUpdateIntervalMilliseconds or 1000)
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    PauseClock(false)
end)
