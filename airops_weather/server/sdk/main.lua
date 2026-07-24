AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.SDK = AirOpsWeather.SDK or {}
AirOpsWeather.SDK.Versions = AirOpsWeather.SDK.Versions or {}

local function resolveVersion(version)
    version = tonumber(
        version
        or (Config.SDK and Config.SDK.defaultVersion)
        or AirOpsWeather.APIVersion
        or 1
    )

    if not Config.SDK.supportedVersions[version] then
        return nil, ('unsupported SDK version: %s'):format(tostring(version))
    end

    local sdk = AirOpsWeather.SDK.Versions[version]

    if not sdk then
        return nil, ('SDK version %d is not registered'):format(version)
    end

    return sdk
end

function AirOpsWeather.SDK.Get(version)
    return resolveVersion(version)
end

exports('GetSDK', function(version)
    return resolveVersion(version)
end)

exports('getSDK', function(version)
    return resolveVersion(version)
end)

exports('GetAPIVersion', function()
    return AirOpsWeather.APIVersion
end)

exports('GetSDKVersions', function()
    local versions = {}

    for version in pairs(AirOpsWeather.SDK.Versions) do
        versions[#versions + 1] = version
    end

    table.sort(versions)
    return versions
end)
