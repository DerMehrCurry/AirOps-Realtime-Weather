AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Zones = AirOpsWeather.Zones or {}

local registry = {}

local function normalize(name)
    name = string.lower(tostring(name or ''))
    if name == '' then
        return nil
    end
    return name
end

local function clone(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[clone(key, seen)] = clone(item, seen)
    end

    return copy
end

function AirOpsWeather.Zones.Register(name, definition)
    name = normalize(name)

    if not name then
        return false, 'zone name must not be empty'
    end

    if type(definition) ~= 'table' then
        return false, 'zone definition must be a table'
    end

    definition.name = name
    definition.label = definition.label or name
    definition.enabled = definition.enabled ~= false
    definition.metadata = definition.metadata or {}

    registry[name] = clone(definition)

    TriggerEvent(AirOpsWeather.Events.zoneRegistered, clone(registry[name]))
    AirOpsWeather.Integrations.Publish('zoneRegistered', registry[name])

    return true
end

function AirOpsWeather.Zones.Exists(name)
    name = normalize(name)
    return name and registry[name] ~= nil or false
end

function AirOpsWeather.Zones.Get(name)
    name = normalize(name)
    return name and clone(registry[name]) or nil
end

function AirOpsWeather.Zones.Resolve(name)
    local defaultZone = normalize(
        name
        or (Config.Zones and Config.Zones.default)
        or (Config.SDK and Config.SDK.defaultZone)
        or AirOpsWeather.DefaultZone
        or 'default'
    )

    if not defaultZone or not registry[defaultZone] then
        return nil, ('unknown weather zone: %s'):format(
            tostring(defaultZone or name)
        )
    end

    if registry[defaultZone].enabled == false then
        return nil, ('weather zone is disabled: %s'):format(defaultZone)
    end

    return defaultZone
end

function AirOpsWeather.Zones.List()
    local zones = {}

    for _, definition in pairs(registry) do
        zones[#zones + 1] = clone(definition)
    end

    table.sort(zones, function(left, right)
        return left.name < right.name
    end)

    return zones
end

function AirOpsWeather.Zones.GetDefault()
    return AirOpsWeather.Zones.Resolve(
        Config.Zones and Config.Zones.default or nil
    )
end

for name, definition in pairs(
    Config.Zones and Config.Zones.definitions or {}
) do
    local ok, errorMessage =
        AirOpsWeather.Zones.Register(name, definition)

    if not ok then
        AirOpsWeather.Error(
            'Failed to register weather zone %s: %s',
            tostring(name),
            tostring(errorMessage)
        )
    end
end

exports('GetWeatherZones', function()
    return AirOpsWeather.Zones.List()
end)

exports('GetWeatherZone', function(name)
    return AirOpsWeather.Zones.Get(name)
end)

exports('RegisterWeatherZone', function(name, definition)
    return AirOpsWeather.Zones.Register(name, definition)
end)
