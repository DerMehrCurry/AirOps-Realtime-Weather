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

local REALTIME_MILLISECONDS_PER_GAME_MINUTE = 60000
local SECONDS_PER_DAY = 86400

function AirOpsWeather.SetTimeState(data)
    state.serverUnixTime = tonumber(data.serverUnixTime) or 0
    state.timezoneOffsetSeconds = tonumber(data.timezoneOffsetSeconds) or 0
    state.receivedAt = GetGameTimer()

    local override = type(data.timeOverride) == 'table' and data.timeOverride or {}
    state.timeOverride.active = override.active == true
    state.timeOverride.secondsOfDay = tonumber(override.secondsOfDay) or 0
    state.timeOverride.setAt = tonumber(override.setAt) or 0
end

local function elapsedClientSeconds()
    local elapsedMilliseconds = GetGameTimer() - state.receivedAt

    -- GetGameTimer wraps after a long client runtime. A fresh server sync follows,
    -- but clamping prevents a temporary negative or accelerated clock beforehand.
    if elapsedMilliseconds < 0 then
        return 0
    end

    return math.floor(elapsedMilliseconds / 1000)
end

local function getRealtimeClock()
    local elapsedSeconds = elapsedClientSeconds()
    local secondsOfDay

    if state.timeOverride.active then
        local serverElapsed = math.max(
            0,
            state.serverUnixTime - state.timeOverride.setAt
        )

        secondsOfDay = (
            state.timeOverride.secondsOfDay
            + serverElapsed
            + elapsedSeconds
        ) % SECONDS_PER_DAY
    else
        secondsOfDay = (
            state.serverUnixTime
            + state.timezoneOffsetSeconds
            + elapsedSeconds
        ) % SECONDS_PER_DAY
    end

    return
        math.floor(secondsOfDay / 3600),
        math.floor((secondsOfDay % 3600) / 60),
        math.floor(secondsOfDay % 60)
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

local function clockDifferenceSeconds(
    currentHour,
    currentMinute,
    currentSecond,
    targetHour,
    targetMinute,
    targetSecond
)
    local current = (currentHour * 3600) + (currentMinute * 60) + currentSecond
    local target = (targetHour * 3600) + (targetMinute * 60) + targetSecond
    local difference = math.abs(current - target)

    return math.min(difference, SECONDS_PER_DAY - difference)
end

CreateThread(function()
    local controlledByAirOps = false

    while true do
        if airOpsControlsTime() and state.serverUnixTime > 0 then
            -- GTA normally advances multiple in-game minutes per real minute.
            -- Explicitly setting 60,000 ms per game minute produces a true 1:1
            -- clock rate and avoids the unreliable PauseClock + override pairing.
            PauseClock(false)
            NetworkOverrideClockMillisecondsPerGameMinute(
                REALTIME_MILLISECONDS_PER_GAME_MINUTE
            )
            controlledByAirOps = true

            local targetHour, targetMinute, targetSecond = getRealtimeClock()
            local difference = clockDifferenceSeconds(
                GetClockHours(),
                GetClockMinutes(),
                GetClockSeconds(),
                targetHour,
                targetMinute,
                targetSecond
            )

            local correctionThreshold = tonumber(
                Config.Time.driftCorrectionThresholdSeconds
            ) or 2

            -- Correct only meaningful drift. The native clock itself now runs at
            -- real speed, reducing visible jumps and unnecessary native calls.
            if difference >= correctionThreshold then
                NetworkOverrideClockTime(
                    targetHour,
                    targetMinute,
                    targetSecond
                )
            end
        elseif controlledByAirOps then
            PauseClock(false)
            controlledByAirOps = false
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
