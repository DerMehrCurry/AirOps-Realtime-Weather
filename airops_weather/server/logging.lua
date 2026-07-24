AirOpsWeather = AirOpsWeather or {}

local LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
    TRACE = 5
}

local repeated = {}

local function configuredLevel()
    local configured = Config.Logging and Config.Logging.level or nil

    if not configured and Config.General and Config.General.debug then
        configured = 'DEBUG'
    end

    configured = string.upper(tostring(configured or 'INFO'))
    return LEVELS[configured] and configured or 'INFO'
end

local function shouldPrint(level)
    return LEVELS[level] <= LEVELS[configuredLevel()]
end

local function formatMessage(message, ...)
    if select('#', ...) > 0 then
        local success, formatted = pcall(string.format, message, ...)
        if success then
            return formatted
        end
    end

    return tostring(message)
end

local function output(level, message)
    local prefix = level == 'INFO'
        and '[AirOps Weather]'
        or ('[AirOps Weather][%s]'):format(level)

    print(('%s %s'):format(prefix, message))
end

function AirOpsWeather.Log(level, message, ...)
    level = string.upper(tostring(level or 'INFO'))

    if not LEVELS[level] or not shouldPrint(level) then
        return false
    end

    local formatted = formatMessage(message, ...)
    local logging = Config.Logging or {}

    if not logging.suppressRepeatedMessages
        or level == 'DEBUG'
        or level == 'TRACE' then
        output(level, formatted)
        return true
    end

    local key = level .. ':' .. formatted
    local now = os.time()
    local window = tonumber(logging.repeatWindowSeconds) or 300
    local entry = repeated[key]

    if not entry or now - entry.firstAt > window then
        if entry and entry.suppressed > 0 then
            output(
                level,
                ('Previous message repeated %d additional time(s): %s')
                    :format(entry.suppressed, formatted)
            )
        end

        repeated[key] = {
            firstAt = now,
            lastAt = now,
            suppressed = 0
        }
        output(level, formatted)
        return true
    end

    entry.lastAt = now
    entry.suppressed = entry.suppressed + 1

    local threshold = tonumber(logging.repeatSummaryThreshold) or 2
    if entry.suppressed == threshold then
        output(
            level,
            ('Further identical messages are being suppressed: %s')
                :format(formatted)
        )
    end

    return false
end

function AirOpsWeather.FlushRepeatedLogs()
    for key, entry in pairs(repeated) do
        if entry.suppressed > 0 then
            local original = key:match('^[^:]+:(.*)$') or key
            output(
                key:match('^([^:]+):') or 'INFO',
                ('Message repeated %d additional time(s): %s')
                    :format(entry.suppressed, original)
            )
        end
    end

    repeated = {}
end

exports('GetLoggingLevel', function()
    return configuredLevel()
end)
