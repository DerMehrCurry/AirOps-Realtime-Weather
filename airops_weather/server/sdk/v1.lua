AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.SDK = AirOpsWeather.SDK or {}
AirOpsWeather.SDK.Versions = AirOpsWeather.SDK.Versions or {}

local function zoneFrom(options)
    if type(options) == 'string' then
        return options
    end

    if type(options) == 'table' then
        return options.zone
    end

    return nil
end

local function hoursFrom(options)
    if type(options) == 'number' then
        return options
    end

    if type(options) == 'table' then
        return options.hours
    end

    return nil
end

local SDK = {
    version = 1,
    resourceVersion = AirOpsWeather.Version,
    defaultZone = (Config.SDK and Config.SDK.defaultZone) or 'default'
}

function SDK.GetWeather(self, options)
    if self ~= SDK then
        options = self
    end

    return AirOpsWeather.API.GetWeatherProfile(zoneFrom(options))
end

function SDK.GetTime(self, options)
    if self ~= SDK then
        options = self
    end

    return AirOpsWeather.API.GetTime(zoneFrom(options))
end

function SDK.GetState(self, options)
    if self ~= SDK then
        options = self
    end

    return AirOpsWeather.API.GetState(zoneFrom(options))
end

function SDK.GetForecast(self, options)
    if self ~= SDK then
        options = self
    end

    return AirOpsWeather.API.GetForecast(
        hoursFrom(options),
        zoneFrom(options)
    )
end

function SDK.GetFlightConditions(self, options)
    if self ~= SDK then
        options = self
    end

    local profile, errorMessage =
        AirOpsWeather.API.GetWeatherProfile(zoneFrom(options))

    if not profile then
        return nil, errorMessage
    end

    return AirOpsWeather.API.GetFlightConditions(profile)
end

function SDK.GetWarnings(self, options)
    if self ~= SDK then
        options = self
    end

    local profile, errorMessage =
        AirOpsWeather.API.GetWeatherProfile(zoneFrom(options))

    if not profile then
        return nil, errorMessage
    end

    return AirOpsWeather.API.GetWarnings(profile)
end

function SDK.GetHealth()
    return AirOpsWeather.Diagnostics.GetHealth()
end

function SDK.GetDiagnostics()
    return AirOpsWeather.Diagnostics.GetDiagnostics()
end

function SDK.GetIntegrations()
    return AirOpsWeather.Diagnostics.GetIntegrations()
end

function SDK.GetProviders()
    return AirOpsWeather.Providers.List()
end

function SDK.GetJSON(self, options)
    if self ~= SDK then
        options = self
    end

    AirOpsWeather.IntegrationMetrics.Increment('sdkCalls')
    return AirOpsWeather.JSON.Get(zoneFrom(options), false)
end

function SDK.GetJSONDocument(self, options)
    if self ~= SDK then
        options = self
    end

    AirOpsWeather.IntegrationMetrics.Increment('sdkCalls')
    return AirOpsWeather.JSON.GetDocument(zoneFrom(options))
end

function SDK.Subscribe(self, eventName, callback)
    if self ~= SDK then
        callback = eventName
        eventName = self
    end

    AirOpsWeather.IntegrationMetrics.Increment('sdkCalls')
    return AirOpsWeather.Integrations.Subscribe(
        eventName,
        callback,
        GetInvokingResource()
    )
end

function SDK.Unsubscribe(self, listenerId)
    if self ~= SDK then
        listenerId = self
    end

    return AirOpsWeather.Integrations.Unsubscribe(listenerId)
end

function SDK.GetIntegrationMetrics()
    return AirOpsWeather.IntegrationMetrics.Get()
end

function SDK.GetMetadata()
    return {
        sdkVersion = SDK.version,
        apiVersion = AirOpsWeather.APIVersion,
        resourceVersion = AirOpsWeather.Version,
        defaultZone = SDK.defaultZone,
        supportedZones = {
            SDK.defaultZone
        },
        provider = AirOpsWeather.Providers.GetActiveName()
    }
end

AirOpsWeather.SDK.Versions[1] = SDK
