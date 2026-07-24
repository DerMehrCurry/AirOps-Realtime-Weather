AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Webhooks = AirOpsWeather.Webhooks or {}

local queue = {}
local processing = false
local lastSentByCategory = {}

local function retryDelay(attempt)
    return math.min(
        (tonumber(Config.Webhooks.retryInitialSeconds) or 15)
            * ((tonumber(Config.Webhooks.retryMultiplier) or 2)
                ^ math.max(0, attempt - 1)),
        tonumber(Config.Webhooks.retryMaximumSeconds) or 300
    )
end

function AirOpsWeather.Webhooks.GetQueueSize()
    return #queue
end

function AirOpsWeather.Webhooks.CanSend(category)
    local now = os.time()
    local limit = tonumber(Config.Webhooks.rateLimitSeconds) or 300
    local last = lastSentByCategory[category] or 0

    return (now - last) >= limit
end

function AirOpsWeather.Webhooks.MarkSent(category)
    lastSentByCategory[category] = os.time()
end

function AirOpsWeather.Webhooks.Enqueue(category, payload)
    if #queue >= (tonumber(Config.Webhooks.maximumQueueSize) or 50) then
        AirOpsWeather.IntegrationMetrics.Increment('webhookDropped')
        AirOpsWeather.Warn('Webhook queue is full; message dropped.')
        return false
    end

    queue[#queue + 1] = {
        category = category,
        payload = payload,
        attempt = 0,
        availableAt = os.time()
    }

    AirOpsWeather.IntegrationMetrics.Increment('webhookQueued')
    return true
end

local function processNext()
    if processing or #queue == 0 then
        return
    end

    local item = queue[1]
    if item.availableAt > os.time() then
        SetTimeout(1000, processNext)
        return
    end

    processing = true
    item.attempt = item.attempt + 1

    AirOpsWeather.Webhooks.SendRaw(item.payload, function(success)
        processing = false

        if success then
            table.remove(queue, 1)
            AirOpsWeather.Webhooks.MarkSent(item.category)
            AirOpsWeather.IntegrationMetrics.Increment('webhookSent')
        else
            AirOpsWeather.IntegrationMetrics.Increment('webhookFailed')

            if item.attempt >=
                (tonumber(Config.Webhooks.maximumAttempts) or 5) then
                table.remove(queue, 1)
                AirOpsWeather.IntegrationMetrics.Increment('webhookDropped')
            else
                item.availableAt = os.time() + retryDelay(item.attempt)
                AirOpsWeather.IntegrationMetrics.Increment('webhookRetried')
            end
        end

        SetTimeout(250, processNext)
    end)
end

CreateThread(function()
    while true do
        processNext()
        Wait(1000)
    end
end)
