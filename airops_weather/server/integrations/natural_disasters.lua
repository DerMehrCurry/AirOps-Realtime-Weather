AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Integrations = AirOpsWeather.Integrations or {}

local settings = Config.Integrations
    and Config.Integrations.naturalDisasters
    or { enabled = false }

local state = {
    available = false,
    externalControl = false,
    controller = nil,
    lastAppliedWeather = nil,
    lastObservedWeather = nil,
    lastApplyGameTimer = 0,
    missingWarningShown = false
}

local function resourceStarted()
    if not settings.enabled then
        return false
    end

    return GetResourceState(settings.resourceName) == 'started'
end

local function callExport(exportName, ...)
    if not resourceStarted() then
        return false, 'resource is not started'
    end

    local arguments = { ... }
    local success, result = pcall(function()
        return exports[settings.resourceName][exportName](
            exports[settings.resourceName],
            table.unpack(arguments)
        )
    end)

    if not success then
        return false, result
    end

    return true, result
end

function AirOpsWeather.Integrations.IsNaturalDisastersConfigured()
    return settings.enabled == true and settings.delegateWeather == true
end

function AirOpsWeather.Integrations.IsNaturalDisastersAvailable()
    state.available = resourceStarted()
    return state.available
end

function AirOpsWeather.Integrations.IsNaturalDisastersEnabled()
    return AirOpsWeather.Integrations.IsNaturalDisastersConfigured()
        and AirOpsWeather.Integrations.IsNaturalDisastersAvailable()
end

function AirOpsWeather.Integrations.IsExternalWeatherControlActive()
    return state.externalControl
end

function AirOpsWeather.Integrations.SetExternalWeatherControl(active, controller)
    if not AirOpsWeather.Integrations.IsNaturalDisastersAvailable() then
        state.externalControl = false
        state.controller = nil
        return false, 'Natural Disasters is not available'
    end

    state.externalControl = active == true
    state.controller = state.externalControl and (controller or 'external') or nil

    if state.externalControl then
        AirOpsWeather.Info('External weather control acquired by %s.', state.controller)
        return true
    end

    AirOpsWeather.Info('External weather control released; restoring real weather.')

    local cache = AirOpsWeather.GetCache()
    if cache and cache.currentWeather then
        AirOpsWeather.Integrations.ApplyNaturalDisastersWeather(cache.currentWeather, true)
    end

    return true
end

function AirOpsWeather.Integrations.ApplyNaturalDisastersWeather(weather, force)
    if not AirOpsWeather.Integrations.IsNaturalDisastersConfigured() then
        return false, 'integration disabled'
    end

    if not AirOpsWeather.Integrations.IsNaturalDisastersAvailable() then
        return false, 'Natural Disasters is not available'
    end

    if state.externalControl and not force then
        AirOpsWeather.Debug(
            'Natural Disasters currently owns weather; cached real weather %s was not applied.',
            weather
        )
        return false, 'external control active'
    end

    local success, result = callExport('SetWeather', weather)
    if not success then
        state.available = false
        AirOpsWeather.Warn('Natural Disasters SetWeather failed: %s', tostring(result))
        return false, result
    end

    state.available = true
    state.lastAppliedWeather = weather
    state.lastObservedWeather = weather
    state.lastApplyGameTimer = GetGameTimer()
    AirOpsWeather.Debug('Delegated baseline weather %s to Natural Disasters.', weather)
    return true
end

function AirOpsWeather.Integrations.GetNaturalDisastersState()
    return {
        configured = AirOpsWeather.Integrations.IsNaturalDisastersConfigured(),
        available = AirOpsWeather.Integrations.IsNaturalDisastersAvailable(),
        externalControl = state.externalControl,
        controller = state.controller,
        lastAppliedWeather = state.lastAppliedWeather,
        lastObservedWeather = state.lastObservedWeather
    }
end

RegisterNetEvent('airops_weather:server:setExternalWeatherControl', function(active, controller)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'airops.weather.integration') then
        return
    end

    AirOpsWeather.Integrations.SetExternalWeatherControl(active, controller)
end)

RegisterCommand('airops_weather_nd_lock', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'airops.weather.integration') then
        return
    end

    AirOpsWeather.Integrations.SetExternalWeatherControl(true, 'natural_disasters')
end, false)

RegisterCommand('airops_weather_nd_release', function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'airops.weather.integration') then
        return
    end

    AirOpsWeather.Integrations.SetExternalWeatherControl(false)
end, false)

exports('setExternalWeatherControl', function(active, controller)
    return AirOpsWeather.Integrations.SetExternalWeatherControl(active, controller)
end)

exports('getNaturalDisastersIntegrationState', function()
    return AirOpsWeather.Integrations.GetNaturalDisastersState()
end)

CreateThread(function()
    if not AirOpsWeather.Integrations.IsNaturalDisastersConfigured() then
        AirOpsWeather.Info('Natural Disasters integration disabled; standalone weather mode active.')
        return
    end

    while true do
        local available = AirOpsWeather.Integrations.IsNaturalDisastersAvailable()

        if not available then
            if not state.missingWarningShown then
                AirOpsWeather.Warn(
                    '%s is not started. AirOps continues automatically in standalone mode.',
                    settings.resourceName
                )
                state.missingWarningShown = true
            end
        else
            if state.missingWarningShown then
                AirOpsWeather.Info(
                    '%s detected; switching to Natural Disasters compatibility mode.',
                    settings.resourceName
                )
            elseif not state.available then
                AirOpsWeather.Info('Natural Disasters compatibility mode active.')
            end

            state.available = true
            state.missingWarningShown = false

            if settings.automaticOwnershipDetection then
                local success, currentWeather = callExport('GetCurrentWeather')

                if success and type(currentWeather) == 'string' then
                    currentWeather = string.upper(currentWeather)
                    state.lastObservedWeather = currentWeather

                    local outsideApplyGrace = (
                        GetGameTimer() - state.lastApplyGameTimer
                    ) > (settings.applyGraceMilliseconds or 5000)

                    if state.lastAppliedWeather
                        and currentWeather ~= state.lastAppliedWeather
                        and outsideApplyGrace
                        and not state.externalControl then
                        state.externalControl = true
                        state.controller = 'natural_disasters:auto'
                        AirOpsWeather.Info(
                            'Natural Disasters weather %s detected; AirOps baseline updates paused.',
                            currentWeather
                        )
                    elseif state.externalControl
                        and currentWeather == state.lastAppliedWeather then
                        state.externalControl = false
                        state.controller = nil
                        AirOpsWeather.Info(
                            'Natural Disasters returned to the AirOps baseline; real-weather control resumed.'
                        )
                    end
                end
            end
        end

        Wait(settings.monitorIntervalMilliseconds or 1000)
    end
end)
