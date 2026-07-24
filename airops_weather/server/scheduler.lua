AirOpsWeather = AirOpsWeather or {}

local activeRequestId = 0
local requestActive = false
local providerUnavailable = false
local lastProviderError = nil

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

function AirOpsWeather.GetSchedulerState()
    return {
        requestActive = requestActive,
        activeRequestId = activeRequestId,
        providerUnavailable = providerUnavailable,
        lastProviderError = lastProviderError
    }
end

local function markProviderUnavailable(reason)
    lastProviderError = reason

    if providerUnavailable then
        return
    end

    providerUnavailable = true
    TriggerEvent(AirOpsWeather.Events.providerUnavailable, {
        reason = reason,
        occurredAt = os.time()
    })
end

local function markProviderRecovered()
    if not providerUnavailable then
        return
    end

    providerUnavailable = false
    local recovery = {
        previousError = lastProviderError,
        recoveredAt = os.time(),
        failures = AirOpsWeather.GetCache().failureCount
    }
    lastProviderError = nil

    AirOpsWeather.Info(
        'Weather provider recovered after %d consecutive failure(s).',
        recovery.failures
    )
    TriggerEvent(AirOpsWeather.Events.providerRecovered, recovery)
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

    local provider = AirOpsWeather.Providers.GetActive()

    if not provider then
        local reason = ('Unknown provider: %s')
            :format(tostring(Config.Provider.name))
        markProviderUnavailable(reason)
        AirOpsWeather.Warn(reason)
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

        local reason = ('Weather request timed out after %d seconds.'):format(timeoutSeconds)
        markProviderUnavailable(reason)
        AirOpsWeather.Warn(
            '%s Retry in %d seconds.',
            reason,
            wait
        )
        AirOpsWeather.CheckCacheHealth()
        AirOpsWeather.ScheduleNextUpdate(wait)
    end)

    AirOpsWeather.Providers.Fetch(function(success, payload, errorMessage)
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

            local reason = tostring(errorMessage or 'unknown')
            markProviderUnavailable(reason)
            AirOpsWeather.Warn(
                'Weather request failed (%d): %s. Retry in %d seconds.',
                failures,
                reason,
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

            local reason = tostring(changedOrError or 'unknown')
            markProviderUnavailable(reason)
            AirOpsWeather.Warn(
                'Response processing failed: %s. Retry in %d seconds.',
                reason,
                wait
            )
            AirOpsWeather.ScheduleNextUpdate(wait)
            return
        end

        AirOpsWeather.Metrics.RecordRequest(true, duration, false)
        markProviderRecovered()
        AirOpsWeather.BroadcastState(-1, changedOrError == true)

        local cache = AirOpsWeather.GetCache()
        AirOpsWeather.ScheduleNextUpdate(interval(cache.weatherClass))
    end)

    return true
end
