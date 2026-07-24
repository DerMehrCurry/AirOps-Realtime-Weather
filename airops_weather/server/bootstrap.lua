-- AirOps Realtime Weather
-- Central server bootstrap.
--
-- FiveM may execute manifest script entries in isolated Lua environments.
-- All server modules are therefore loaded explicitly into this bootstrap's
-- environment so the shared AirOpsWeather namespace remains available.

AirOpsWeather = AirOpsWeather or {}

local modules = {
    'server/logging.lua',
    'server/providers/base.lua',
    'server/validation.lua',
    'server/metrics.lua',
    'server/cache.lua',
    'server/weather_engine.lua',
    'server/timeline.lua',
    'server/integrations/manager.lua',
    'server/integrations/events.lua',
    'server/integrations/metrics.lua',
    'server/integrations/natural_disasters.lua',
    'server/override.lua',
    'server/providers/openmeteo.lua',
    'server/providers/mock.lua',
    'server/zones/registry.lua',
    'server/zones/state.lua',
    'server/scheduler.lua',
    'server/api.lua',
    'server/sdk/v1.lua',
    'server/sdk/main.lua',
    'server/json/schema.lua',
    'server/json/export.lua',
    'server/webhooks/embeds.lua',
    'server/webhooks/queue.lua',
    'server/webhooks/discord.lua',
    'server/selftest/checks.lua',
    'server/selftest/command.lua',
    'server/diagnostics.lua',
    'server/main.lua'
}

local resourceName = GetCurrentResourceName()

local function loadModule(path)
    local source = LoadResourceFile(resourceName, path)

    if not source then
        error(('Unable to load server module: %s'):format(path), 0)
    end

    local chunk, compileError = load(source, ('@@%s/%s'):format(resourceName, path), 't', _ENV)

    if not chunk then
        error(('Unable to compile server module %s: %s'):format(path, tostring(compileError)), 0)
    end

    local ok, runtimeError = xpcall(chunk, debug.traceback)

    if not ok then
        error(('Unable to initialize server module %s:\n%s'):format(path, tostring(runtimeError)), 0)
    end
end

for _, path in ipairs(modules) do
    loadModule(path)
end
