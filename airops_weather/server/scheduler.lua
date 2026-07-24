AirOpsWeather = AirOpsWeather or {}

local activeRequestId = 0
local requestActive = false

local function interval(weatherClass)
    if weatherClass == 'stable' then
        return Config.AdaptivePolling.stableSeconds
    elseif weatherClass == 'changing' then
        return Config.AdaptivePolling.changingSeconds
    elseif weatherClass == 'precipitation' then
        return Config.AdaptivePolling.precipitationSeconds
    elseif weatherClass == 'severe' then
        return Config.AdaptivePolling.severeSeconds
    end

    return Config.AdaptivePolling.normalSeconds
end

local function retry(count)
    return math.min(
        Config.Retry.initialSeconds
            * (Config.Retry.multiplier ^ math.max(0, count - 1)),
        Config.Retry.maximumSeconds
    )
end

function AirOpsWeather.ScheduleNextUpdate(seconds)
    local delay = math.max(30, math.floor(seconds))
    AirOpsWeather.SetNextPoll(os.time() + delay)

    SetTimeout(delay * 1000, function()
        AirOpsWeather.UpdateWeather()
    end)

    AirOpsWeather.Debug('Next request in %d seconds.', delay)
end

function AirOpsWeather.UpdateWeather()
    if requestActive then
        AirOpsWeather.Debug('Provider request skipped because another request is active.')
        return false
    end

    local provider = string.lower(Config.Provider.name or 'openmeteo')
        == 'openmeteo'
        and AirOpsWeather.Providers.OpenMeteo
        or nil

    if not provider then
        AirOpsWeather.Warn('Unknown provider: %s', Config.Provider.name)
        return false
    end

    requestActive = true
    activeRequestId = activeRequestId + 1

    local requestId = activeRequestId
    local requestStartedAt = GetGameTimer()
    local callbackCompleted = false
    local timeoutSeconds = math.max(
        5,
        tonumber(Config.Retry.requestTimeoutSeconds) or 20
    )

    SetTimeout(timeoutSeconds * 1000, function()
        if callbackCompleted
            or requestId ~= activeRequestId
            or not requestActive then
            return
        end

        callbackCompleted = true
        requestActive = false

        local duration = GetGameTimer() - requestStartedAt
        AirOpsWeather.Metrics.RecordRequest(false, duration, true)

        local failures = AirOpsWeather.RegisterFailure()
        local wait = retry(failures)

        AirOpsWeather.Warn(
            'Weather request timed out after %d seconds. Retry in %d seconds.',
            timeoutSeconds,
            wait
        )
        AirOpsWeather.CheckCacheHealth()
        AirOpsWeather.ScheduleNextUpdate(wait)
    end)

    provider(function(success, payload, errorMessage)
        if callbackCompleted or requestId ~= activeRequestId then
            AirOpsWeather.Debug('Late provider callback ignored.')
            return
        end

        callbackCompleted = true
        requestActive = false

        local duration = GetGameTimer() - requestStartedAt

        if not success then
            AirOpsWeather.Metrics.RecordRequest(false, duration, false)

            local failures = AirOpsWeather.RegisterFailure()
            local wait = retry(failures)

            AirOpsWeather.Warn(
                'Weather request failed (%d): %s. Retry in %d seconds.',
                failures,
                errorMessage or 'unknown',
                wait
            )
            AirOpsWeather.CheckCacheHealth()
            AirOpsWeather.ScheduleNextUpdate(wait)
            return
        end

        local processed, changedOrError =
            AirOpsWeather.ProcessProviderPayload(payload)

        if not processed then
            AirOpsWeather.Metrics.RecordRequest(false, duration, false)

            local failures = AirOpsWeather.RegisterFailure()
            local wait = retry(failures)

            AirOpsWeather.Warn(
                'Response processing failed: %s. Retry in %d seconds.',
                changedOrError or 'unknown',
                wait
            )
            AirOpsWeather.ScheduleNextUpdate(wait)
            return
        end

        AirOpsWeather.Metrics.RecordRequest(true, duration, false)
        AirOpsWeather.BroadcastState(-1, changedOrError == true)

        local cache = AirOpsWeather.GetCache()
        AirOpsWeather.ScheduleNextUpdate(interval(cache.weatherClass))
    end)

    return true
end
