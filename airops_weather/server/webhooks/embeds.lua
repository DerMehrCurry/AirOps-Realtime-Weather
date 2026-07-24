AirOpsWeather = AirOpsWeather or {}
AirOpsWeather.Webhooks = AirOpsWeather.Webhooks or {}

local COLORS = {
    INFO = 3447003,
    SUCCESS = 5763719,
    WARNING = 16776960,
    DANGER = 15548997
}

function AirOpsWeather.Webhooks.BuildEmbed(kind, data)
    data = data or {}

    local title = data.title or 'AirOps Weather'
    local description = data.description or ''
    local color = COLORS[data.level or 'INFO'] or COLORS.INFO

    local fields = data.fields or {}
    fields[#fields + 1] = {
        name = 'Version',
        value = AirOpsWeather.Version,
        inline = true
    }

    return {
        title = title,
        description = description,
        color = color,
        fields = fields,
        footer = {
            text = 'AirOps Development'
        },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }
end
