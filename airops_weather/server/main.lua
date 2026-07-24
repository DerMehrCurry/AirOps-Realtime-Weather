AirOpsWeather = AirOpsWeather or {}

local function hasAce(source, permission)
    return source == 0 or IsPlayerAceAllowed(source, permission)
end

local function reply(source, message)
    if source == 0 then
        AirOpsWeather.Info('%s', message)
        return
    end

    TriggerClientEvent('chat:addMessage', source, {
        color = { 80, 180, 255 },
        args = { 'AirOps Weather', message }
    })
end

local function usage(source)
    reply(source, 'Verwendung: /airops weather <typ> [dauer_min]')
    reply(source, 'Verwendung: /airops time <stunde> <minute> [dauer_min]')
    reply(source, 'Verwendung: /airops realtime <weather|time|all>')
    reply(source, 'Diagnose: /airops <status|health|forecast|warnings|metrics|integrations>')
end

local function validateDuration(value)
    if value == nil then
        return true, 0
    end

    local duration = tonumber(value)
    if not duration or duration < 0 then
        return false, nil
    end

    local maximum = tonumber(Config.Override.maximumDurationMinutes) or 1440
    if duration > maximum then
        return false, nil
    end

    if duration == 0 and not Config.Override.allowPermanent then
        return false, nil
    end

    return true, duration
end

RegisterNetEvent(AirOpsWeather.Events.requestSync, function()
    AirOpsWeather.BroadcastState(source)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local valid = AirOpsWeather.Validation.Run()

    AirOpsWeather.Info(
        'Starting v%s for %s (%.4f, %.4f).',
        AirOpsWeather.Version,
        Config.Location.name,
        Config.Location.latitude,
        Config.Location.longitude
    )
    if not valid then
        AirOpsWeather.Error(
            'Critical configuration errors detected. Provider startup has been blocked.'
        )
        return
    end

    AirOpsWeather.UpdateWeather()

    SetTimeout(1000, function()
        if AirOpsWeather.API and AirOpsWeather.API.EmitChanges then
            AirOpsWeather.API.EmitChanges(true)
        end
    end)
end)

RegisterCommand('airops_weather_update', function(source)
    if not hasAce(source, 'airops.weather.update') then
        return
    end

    AirOpsWeather.Info('Manual provider update requested.')
    AirOpsWeather.UpdateWeather()
end, false)

RegisterCommand(Config.Override.command or 'airops', function(source, args)
    if not Config.Override.enabled then
        reply(source, 'Manual overrides are disabled in config.lua.')
        return
    end

    local action = string.lower(tostring(args[1] or ''))

    if action == 'status' then
        ExecuteCommand('airops_weather_status')
        local override = AirOpsWeather.Override.GetState()
        reply(source, ('Wettermodus: %s | Zeitmodus: %s'):format(
            override.weather.active and ('Override ' .. tostring(override.weather.value)) or 'Realtime',
            override.time.active and 'Override' or 'Realtime'
        ))
        return
    end

    local diagnosticActions = {
        health = true,
        forecast = true,
        warnings = true,
        metrics = true,
        integrations = true
    }

    if diagnosticActions[action] then
        if not hasAce(source, 'airops.weather.status') then
            reply(source, 'Keine Berechtigung: airops.weather.status')
            return
        end

        if action == 'health' then
            local health = AirOpsWeather.Diagnostics.GetHealth()
            reply(
                source,
                ('Health: %s | Provider: %s | Cache: %ss | Probleme: %d')
                    :format(
                        health.status,
                        health.provider.available and 'online' or 'offline',
                        health.cache.ageSeconds,
                        #health.issues
                    )
            )

            for _, issue in ipairs(health.issues) do
                reply(
                    source,
                    ('[%s] %s: %s')
                        :format(issue.severity, issue.code, issue.message)
                )
            end
        elseif action == 'forecast' then
            local forecast = AirOpsWeather.Diagnostics.GetForecast()
            reply(source, ('Forecast-Timeline: %d Einträge'):format(forecast.count))

            local maximum = tonumber(
                Config.Diagnostics.maximumForecastEntriesInChat
            ) or 8

            for index = 1, math.min(maximum, forecast.count) do
                local entry = forecast.entries[index]
                reply(
                    source,
                    ('%d. %s in %ds%s -> %s')
                        :format(
                            index,
                            entry.weather,
                            entry.secondsFromNow,
                            entry.intermediate and ' (Übergang)' or '',
                            entry.targetWeather or entry.weather
                        )
                )
            end
        elseif action == 'warnings' then
            local warnings = AirOpsWeather.API.GetWarnings()
            reply(source, ('Aktive Warnungen: %d'):format(#warnings))

            for _, warning in ipairs(warnings) do
                reply(
                    source,
                    ('[%s] %s: %s')
                        :format(warning.severity, warning.code, warning.message)
                )
            end
        elseif action == 'metrics' then
            local metrics = AirOpsWeather.Metrics.Get()
            reply(
                source,
                ('Requests %d/%d | Fehler %d | Timeouts %d | Broadcasts %d | unterdrückt %d')
                    :format(
                        metrics.apiSuccesses,
                        metrics.apiRequests,
                        metrics.apiFailures,
                        metrics.apiTimeouts,
                        metrics.broadcasts,
                        metrics.suppressedBroadcasts
                    )
            )
            reply(
                source,
                ('Antwortzeit zuletzt/Ø: %d/%dms | Wetterwechsel: %d | Uptime: %ds')
                    :format(
                        metrics.lastRequestDurationMilliseconds,
                        metrics.averageRequestDurationMilliseconds,
                        metrics.weatherChanges,
                        metrics.uptimeSeconds
                    )
            )
        elseif action == 'integrations' then
            local integrations =
                AirOpsWeather.Diagnostics.GetIntegrations().naturalDisasters

            reply(
                source,
                ('Natural Disasters | Resource: %s | verfügbar: %s | externe Kontrolle: %s | Controller: %s')
                    :format(
                        integrations.resourceName,
                        tostring(integrations.available),
                        tostring(integrations.externalControl),
                        tostring(integrations.controller or 'none')
                    )
            )
        end

        return
    end

    if not hasAce(source, 'airops.weather.override') then
        reply(source, 'Keine Berechtigung: airops.weather.override')
        return
    end

    if action == 'weather' then
        local weather = args[2]
        local validDuration, duration = validateDuration(args[3])

        if not weather or not validDuration then
            usage(source)
            return
        end

        local success, errorMessage = AirOpsWeather.Override.SetWeather(
            weather,
            duration,
            source == 0 and 'console' or ('player:' .. source)
        )

        reply(source, success and ('Wetter-Override gesetzt: ' .. string.upper(weather)) or errorMessage)
        return
    end

    if action == 'time' then
        local validDuration, duration = validateDuration(args[4])
        if not args[2] or not args[3] or not validDuration then
            usage(source)
            return
        end

        local success, errorMessage = AirOpsWeather.Override.SetTime(
            args[2],
            args[3],
            duration,
            source == 0 and 'console' or ('player:' .. source)
        )

        reply(source, success and ('Zeit-Override gesetzt: %02d:%02d'):format(tonumber(args[2]), tonumber(args[3])) or errorMessage)
        return
    end

    if action == 'realtime' then
        local scope = string.lower(tostring(args[2] or 'all'))
        if scope ~= 'weather' and scope ~= 'time' and scope ~= 'all' then
            usage(source)
            return
        end

        local changed = AirOpsWeather.Override.Clear(scope, 'manual resume')
        reply(source, changed and ('Realtime wieder aktiv: ' .. scope) or 'Kein passender Override aktiv.')
        return
    end

    usage(source)
end, false)


RegisterCommand('airops_weather_health', function(source)
    if not hasAce(source, 'airops.weather.status') then return end

    local health = AirOpsWeather.Diagnostics.GetHealth()
    AirOpsWeather.Info(
        'Health | status=%s | provider=%s | cacheAge=%ds | stale=%s | issues=%d',
        health.status,
        health.provider.available and 'available' or 'unavailable',
        health.cache.ageSeconds,
        tostring(health.cache.stale),
        #health.issues
    )

    for _, issue in ipairs(health.issues) do
        AirOpsWeather.Warn(
            'Health issue | severity=%s | code=%s | %s',
            issue.severity,
            issue.code,
            issue.message
        )
    end
end, false)

RegisterCommand('airops_weather_forecast', function(source)
    if not hasAce(source, 'airops.weather.status') then return end

    local forecast = AirOpsWeather.Diagnostics.GetForecast()
    AirOpsWeather.Info(
        'Forecast diagnostics | generation=%d | entries=%d',
        forecast.generation,
        forecast.count
    )

    for _, entry in ipairs(forecast.entries) do
        AirOpsWeather.Info(
            'Forecast #%d | weather=%s | in=%ds | type=%s | target=%s | providerTime=%s',
            entry.index,
            entry.weather,
            entry.secondsFromNow,
            entry.intermediate and 'transition' or 'target',
            tostring(entry.targetWeather),
            tostring(entry.providerTime)
        )
    end
end, false)

RegisterCommand('airops_weather_metrics', function(source)
    if not hasAce(source, 'airops.weather.status') then return end
    ExecuteCommand('airops_weather_status')
end, false)

RegisterCommand('airops_weather_integrations', function(source)
    if not hasAce(source, 'airops.weather.status') then return end

    local integration =
        AirOpsWeather.Diagnostics.GetIntegrations().naturalDisasters

    AirOpsWeather.Info(
        'Natural Disasters | resource=%s | available=%s | externalControl=%s | controller=%s | lastObserved=%s',
        integration.resourceName,
        tostring(integration.available),
        tostring(integration.externalControl),
        tostring(integration.controller),
        tostring(integration.lastObservedWeather)
    )
end, false)

RegisterCommand('airops_weather_status', function(source)
    if not hasAce(source, 'airops.weather.status') then
        return
    end

    local cache = AirOpsWeather.GetCache()
    local nextEntry = cache.timeline[1]
    local override = AirOpsWeather.Override.GetState()
    local integration = AirOpsWeather.Integrations
        and AirOpsWeather.Integrations.GetNaturalDisastersState
        and AirOpsWeather.Integrations.GetNaturalDisastersState()
        or nil

    local cacheHealth = AirOpsWeather.CheckCacheHealth()
    local health = AirOpsWeather.Diagnostics.GetHealth()
    local metrics = AirOpsWeather.Metrics.Get()

    AirOpsWeather.Info(
        'Status v%s | weather=%s | weatherMode=%s | timeMode=%s | cacheAge=%ds | stale=%s | timeline=%d | next=%s | nextPoll=%ds',
        AirOpsWeather.Version,
        cache.currentWeather,
        override.weather.active and 'manual' or 'realtime',
        override.time.active and 'manual' or 'realtime',
        cacheHealth.ageSeconds,
        tostring(cacheHealth.stale),
        #cache.timeline,
        nextEntry and (nextEntry.weather .. ' in ' .. math.max(0, nextEntry.at - os.time()) .. 's' .. (nextEntry.intermediate and ' (transition)' or ' (target)')) or 'none',
        cache.nextPollAt > 0 and math.max(0, cache.nextPollAt - os.time()) or -1
    )

    AirOpsWeather.Info(
        'Health | status=%s | issues=%d | configuration=%s',
        health.status,
        #health.issues,
        health.configuration.valid and 'valid' or 'invalid'
    )

    if integration then
        AirOpsWeather.Info(
            'Natural Disasters | available=%s | externalControl=%s | controller=%s',
            tostring(integration.available),
            tostring(integration.externalControl),
            tostring(integration.controller)
        )
    end

    AirOpsWeather.Info(
        'Performance | requests=%d | success=%d | failures=%d | timeouts=%d | last=%dms | average=%dms | broadcasts=%d | suppressed=%d | directSyncs=%d',
        metrics.apiRequests,
        metrics.apiSuccesses,
        metrics.apiFailures,
        metrics.apiTimeouts,
        metrics.lastRequestDurationMilliseconds,
        metrics.averageRequestDurationMilliseconds,
        metrics.broadcasts,
        metrics.suppressedBroadcasts,
        metrics.directSyncs
    )

    AirOpsWeather.Info(
        'Engine | weatherChanges=%d | timelineBuilds=%d | timelineExecutions=%d | uptime=%ds',
        metrics.weatherChanges,
        metrics.timelineBuilds,
        metrics.timelineExecutions,
        metrics.uptimeSeconds
    )
end, false)

exports('getWeatherData', function()
    if AirOpsWeather.API and AirOpsWeather.API.GetState then
        return AirOpsWeather.API.GetState()
    end

    return AirOpsWeather.PublicState()
end)

exports('forceWeatherUpdate', function()
    return AirOpsWeather.UpdateWeather()
end)

exports('getForecastTimeline', function()
    if AirOpsWeather.API and AirOpsWeather.API.GetForecast then
        return AirOpsWeather.API.GetForecast()
    end

    return AirOpsWeather.GetCache().timeline
end)
