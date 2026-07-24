AirOpsWeather = AirOpsWeather or {}

local state = {
    serverUnixTime = 0,
    timezoneOffsetSeconds = 0,
    receivedAt = 0,
    timeOverride = {
        active = false,
        secondsOfDay = 0,
        setAt = 0
    }
}

function AirOpsWeather.SetTimeState(data)
    state.serverUnixTime = tonumber(data.serverUnixTime) or 0
    state.timezoneOffsetSeconds = tonumber(data.timezoneOffsetSeconds) or 0
    state.receivedAt = GetGameTimer()

    local override = type(data.timeOverride) == 'table' and data.timeOverride or {}
    state.timeOverride.active = override.active == true
    state.timeOverride.secondsOfDay = tonumber(override.secondsOfDay) or 0
    state.timeOverride.setAt = tonumber(override.setAt) or 0
end

local function getRealtimeClock()
    local elapsedSeconds = math.floor((GetGameTimer() - state.receivedAt) / 1000)
    local secondsOfDay

    if state.timeOverride.active then
        local serverElapsed = math.max(0, state.serverUnixTime - state.timeOverride.setAt)
        secondsOfDay = (state.timeOverride.secondsOfDay + serverElapsed + elapsedSeconds) % 86400
    else
        local localEpoch = state.serverUnixTime
            + state.timezoneOffsetSeconds
            + elapsedSeconds
        secondsOfDay = localEpoch % 86400
    end
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
