AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Webhooks = AirOpsWeather.Webhooks or {}

function AirOpsWeather.Webhooks.SendRaw(payload, callback)
    if not Config.Webhooks.enabled
        or tostring(Config.Webhooks.url or '') == '' then
        if callback then
            callback(false)
        end
        return
    end

    PerformHttpRequest(
        Config.Webhooks.url,
        function(statusCode)
            if callback then
                callback(statusCode >= 200 and statusCode < 300)
            end
        end,
        'POST',
        json.encode(payload),
        { ['Content-Type'] = 'application/json' }
    )
end

function AirOpsWeather.Webhooks.Notify(category, embedData)
    if not Config.Webhooks.enabled then
        return false
    end

    if not AirOpsWeather.Webhooks.CanSend(category) then
        return false
    end

    return AirOpsWeather.Webhooks.Enqueue(category, {
        username = Config.Webhooks.username,
        avatar_url = Config.Webhooks.avatarUrl,
        embeds = {
            AirOpsWeather.Webhooks.BuildEmbed(category, embedData)
        }
    })
end

local function field(name, value, inline)
    return {
        name = name,
        value = tostring(value),
        inline = inline == true
    }
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName()
        or not Config.Webhooks.startup then
        return
    end

    SetTimeout(1500, function()
        AirOpsWeather.Webhooks.Notify('startup', {
            title = 'AirOps Weather gestartet',
            description = 'Die Wetterressource ist verfügbar.',
            level = 'SUCCESS',
            fields = {
                field('Provider', AirOpsWeather.Providers.GetActiveName(), true),
                field('API', 'v' .. AirOpsWeather.APIVersion, true),
                field('SDK', 'v' .. Config.SDK.defaultVersion, true)
            }
        })
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName()
        or not Config.Webhooks.shutdown then
        return
    end

    local payload = {
        username = Config.Webhooks.username,
        avatar_url = Config.Webhooks.avatarUrl,
        embeds = {
            AirOpsWeather.Webhooks.BuildEmbed('shutdown', {
                title = 'AirOps Weather gestoppt',
                description = 'Die Wetterressource wurde beendet.',
                level = 'WARNING'
            })
        }
    }

    -- Resource shutdown does not leave enough time for the retry queue.
    -- Start the HTTP request directly while the resource is still stopping.
    AirOpsWeather.Webhooks.SendRaw(payload)
end)

AddEventHandler(AirOpsWeather.Events.providerUnavailable, function(data)
    if not Config.Webhooks.providerFailure then
        return
    end

    AirOpsWeather.Webhooks.Notify('providerFailure', {
        title = 'Wetteranbieter nicht verfügbar',
        description = tostring(data.reason or 'Unbekannter Fehler'),
        level = 'DANGER'
    })
end)

AddEventHandler(AirOpsWeather.Events.providerRecovered, function(data)
    if not Config.Webhooks.providerRecovered then
        return
    end

    AirOpsWeather.Webhooks.Notify('providerRecovered', {
        title = 'Wetteranbieter wieder verfügbar',
        description = 'Die reguläre Wetterabfrage wurde wiederhergestellt.',
        level = 'SUCCESS',
        fields = {
            field('Fehlversuche', data.failures or 0, true)
        }
    })
end)

AddEventHandler(AirOpsWeather.Events.warningsChanged, function(warnings)
    local highest = nil
    local rank = { INFO = 1, YELLOW = 2, ORANGE = 3, RED = 4 }
    local aliases = {
        info = 'INFO',
        advisory = 'YELLOW',
        warning = 'ORANGE',
        severe = 'RED',
        critical = 'RED'
    }

    for _, warning in ipairs(warnings or {}) do
        local severity = tostring(warning.severity or 'INFO')
        severity = aliases[string.lower(severity)] or string.upper(severity)

        local normalized = {}
        for key, value in pairs(warning) do
            normalized[key] = value
        end
        normalized.severity = severity

        if not highest
            or (rank[severity] or 0) > (rank[highest.severity] or 0) then
            highest = normalized
        end
    end

    if not highest then
        return
    end

    if Config.Webhooks.severeWeather
        and (highest.severity == 'ORANGE' or highest.severity == 'RED') then
        AirOpsWeather.Webhooks.Notify('severeWeather', {
            title = 'Schwere Wetterwarnung',
            description = highest.message or highest.code,
            level = highest.severity == 'RED' and 'DANGER' or 'WARNING',
            fields = {
                field('Warncode', highest.code or 'UNKNOWN', true),
                field('Stufe', highest.severity, true)
            }
        })
    end

    if Config.Webhooks.flightWarnings then
        local flight = AirOpsWeather.API.GetFlightConditions()
        if flight and flight.category
            and (flight.category == 'ORANGE' or flight.category == 'RED') then
            AirOpsWeather.Webhooks.Notify('flightWarnings', {
                title = 'Eingeschränkter Flugbetrieb',
                description = flight.summary or
                    ('Flugkategorie: ' .. flight.category),
                level = flight.category == 'RED' and 'DANGER' or 'WARNING',
                fields = {
                    field('Kategorie', flight.category, true)
                }
            })
        end
    end
end)

exports('SendWebhookNotification', function(category, embedData)
    return AirOpsWeather.Webhooks.Notify(category, embedData)
end)
