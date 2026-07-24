<p align="center">
  <img src="assets/AirOps-Development-Banner.png" alt="AirOps Development Banner">
</p>

<p align="center">
  <strong>CODE. CREATE. DEPLOY.</strong><br>
  Built for Roleplay. Made for Community.
</p>

# AirOps Realtime Weather – Community Edition

Core-unabhängige Echtzeit-Wetter- und Zeitsynchronisation für FiveM.

> Die Community Edition ist kostenlos. Wenn du dafür bei einem Drittanbieter bezahlt hast, wurdest du getäuscht.

## Self-Test Validation Hotfix – v0.7.2.3

v0.7.2.3 fixes the configuration check in the built-in self-test. The validation API returns a boolean status and a detailed report; the self-test previously treated the boolean as the report table.

- provider registry now initializes before validation and concrete providers
- fixes `AirOpsWeather.Providers` being `nil` during Open-Meteo registration
- fixes the resulting `AirOpsWeather.Validation` startup error
- no configuration, API, SDK, or export changes

The stabilization improvements from v0.7.2 remain included:


- stable delta detection without timestamp-only changes
- real pretty JSON output
- single-delivery zone events
- corrected self-test error reporting
- standardized warning severities
- reliable direct shutdown webhook dispatch

No public export or SDK v1 method was removed.

## Version 0.7.2.3

Diese Entwicklungsversion enthält:

- reale Wetterdaten über Open-Meteo
- reale lokale Uhrzeit mit Sommer-/Winterzeit
- serverseitigen Wettercache
- adaptive API-Abfragen
- 12-Stunden-Wetter-Timeline
- flexible, reproduzierbare Wechsel um stündliche Prognosepunkte
- mehrstufige Übergänge wie `CLOUDS -> OVERCAST -> RAIN`
- Windgeschwindigkeit und Windrichtung
- automatischen Retry-Backoff bei API-Fehlern
- Standalone-Betrieb ohne Framework
- optionale Kompatibilität mit `night_natural_disasters`
- manuelle Wetter- und Zeit-Overrides
- zeitlich begrenzte Overrides mit automatischer Rückkehr zur Echtzeit
- Serverbefehle, ACE-Rechte und Exports für andere Ressourcen
- bedingte Client-Broadcasts statt Versand nach jedem API-Abruf
- HTTP-Watchdog mit Schutz vor verspäteten Antworten
- Cache-Stale-Erkennung bei längeren Provider-Ausfällen
- adaptive Natural-Disasters-Prüfung
- interne Performance- und Stabilitätsmetriken
- öffentliche Server- und Client-API für externe Ressourcen
- standardisierte Wetterprofile mit Straße, Fluglage und Warnungen
- ereignisbasierte Zustands-, Forecast- und Override-Änderungen
- Luftfeuchtigkeit und Luftdruck aus Open-Meteo
- Health-System mit `HEALTHY`, `DEGRADED` und `UNHEALTHY`
- automatische Konfigurationsvalidierung beim Start
- erweiterte Admin- und Konsolendiagnosen
- Provider-Ausfall-, Recovery- und Health-Events
- Logging-Stufen und Unterdrückung wiederholter Fehlermeldungen

## Installation

1. Den Ordner `airops_weather` in den Ressourcenordner des Servers kopieren.
2. Standort und gewünschte Optionen in `config.lua` anpassen.
3. In der `server.cfg` eintragen:

```cfg
ensure airops_weather
```

Mit Natural Disasters:

```cfg
ensure night_natural_disasters
ensure airops_weather
```

AirOps erkennt automatisch, ob Natural Disasters läuft. Ohne die Ressource arbeitet AirOps eigenständig weiter.

## Grundkonfiguration

```lua
Config.Location = {
    name = 'Lüneburg',
    latitude = 53.2464,
    longitude = 10.4115,
    timezone = 'Europe/Berlin'
}

Config.Provider = {
    name = 'openmeteo',
    forecastHours = 12
}
```

Die aktive Wetter-Timeline bleibt bewusst auf zwölf Stunden begrenzt. Längere Tagesprognosen gehören später in optionale Schnittstellen für Smartphone-, Discord- oder andere Anzeigesysteme.

## Flexible Wetterwechsel

Die stündlichen Werte von Open-Meteo sind Referenzpunkte und keine harten Umschaltzeiten. AirOps berechnet einen reproduzierbaren Versatz und fügt sinnvolle Zwischenstufen ein.

Beispiel:

```text
Open-Meteo:       16:00 RAIN
AirOps-Timeline:  15:43 OVERCAST -> 15:51 RAIN
```

Konfiguration:

```lua
Config.Forecast = {
    enabled = true,
    flexibleTransitions = true,
    maximumOffsetMinutes = 20,
    transitionStepMinutes = 8,
    minimumEntrySpacingSeconds = 180,
    minimumFutureSeconds = 120
}
```

Der Versatz basiert auf Standort, Prognosezeit und Zielwetter. Dadurch bleibt die Planung nach einem Ressourcen-Neustart identisch.

## Echtzeit-Uhr

AirOps pausiert die beschleunigte native GTA-Uhr und berechnet die reale Zeit lokal weiter. Dadurch springt die Anzeige nicht mehr regelmäßig mehrere Minuten vor und zurück.

```lua
Config.Time = {
    enabled = true,
    syncIntervalSeconds = 300,
    localUpdateIntervalMilliseconds = 1000
}
```

## Manuelle Overrides

AirOps unterstützt voneinander getrennte Wetter- und Zeit-Overrides.

### Wetter setzen

```text
/airops weather rain
/airops weather thunder 30
```

Die optionale Zahl ist die Dauer in Minuten. Ohne Dauer bleibt der Override aktiv, bis Realtime wieder eingeschaltet wird.

### Zeit setzen

```text
/airops time 22 30
/airops time 22 30 60
```

Die manuell gesetzte Uhrzeit läuft ab diesem Zeitpunkt in Echtzeit weiter. Im zweiten Beispiel endet der Override nach 60 Minuten.

### Realtime wieder aktivieren

```text
/airops realtime weather
/airops realtime time
/airops realtime all
```

### Status

```text
/airops status
airops_weather_status
```

Der ausführliche Statusbefehl schreibt unter anderem aktuellen Modus, Cache-Alter, Timeline und Natural-Disasters-Zustand in die Serverkonsole.

## Prioritätssystem

```text
Natural Disasters
        ↓
Manual Override
        ↓
Realtime-Wetter und Realtime-Zeit
```

Wenn Natural Disasters eine Katastrophe steuert, überschreibt AirOps das Katastrophenwetter nicht. Ein währenddessen gesetzter manueller Wetter-Override bleibt gespeichert und übernimmt nach der Freigabe. Providerdaten und Timeline werden im Hintergrund weiterhin aktualisiert.

Zeit-Overrides bleiben standardmäßig unabhängig von Natural Disasters aktiv. Das kann über `pauseAirOpsTime` geändert werden.

## Override-Konfiguration

```lua
Config.Override = {
    enabled = true,
    command = 'airops',
    weatherTransitionSeconds = 180,
    allowPermanent = true,
    maximumDurationMinutes = 1440
}
```

## ACE-Berechtigungen

```cfg
add_ace group.admin airops.weather.override allow
add_ace group.admin airops.weather.update allow
add_ace group.admin airops.weather.status allow
add_ace group.admin airops.weather.integration allow
```

Bedeutung:

- `airops.weather.override`: Wetter und Zeit manuell ändern
- `airops.weather.update`: sofortige Open-Meteo-Abfrage auslösen
- `airops.weather.status`: ausführlichen Status abrufen
- `airops.weather.integration`: externe Wetterkontrolle sperren oder freigeben

Die Serverkonsole darf alle Befehle ohne ACE-Eintrag verwenden.

## Natural-Disasters-Kompatibilität

```lua
Config.Integrations = {
    naturalDisasters = {
        enabled = true,
        resourceName = 'night_natural_disasters',
        delegateWeather = true,
        idleMonitorIntervalMilliseconds = 10000,
        activeMonitorIntervalMilliseconds = 2000,
        pauseAirOpsTime = false,
        automaticOwnershipDetection = true
    }
}
```

Wenn Natural Disasters läuft, übergibt AirOps das Basiswetter über dessen `SetWeather`-Export. AirOps verwendet dann keine konkurrierenden Client-Wetternatives.

Testbefehle:

```text
airops_weather_nd_lock
airops_weather_nd_release
```

Explizite Steuerung aus einer anderen Serverressource:

```lua
exports['airops_weather']:setExternalWeatherControl(true, 'natural_disasters')
exports['airops_weather']:setExternalWeatherControl(false)
```







## Release Candidate foundation

Diese Version friert die öffentliche API und das SDK v1 für den restlichen
v0.7-Zyklus ein.

### Stabilisiertes Zonensystem

```lua
local zones =
    exports['airops_weather']:GetWeatherZones()

local airportZone =
    exports['airops_weather']:GetWeatherZone('airport')
```

Mehrere Zonen können bereits registriert und von Integrationen abgefragt
werden. Standardmäßig teilen alle registrierten Zonen weiterhin denselben
globalen Wetterzustand. Unabhängiges regionales Wetter wird noch nicht
aktiviert.

### Selbstprüfung

```text
airops_weather_selftest
```

Die Prüfung kontrolliert Konfiguration, Provider, Standardzone, SDK,
JSON-Schema, Event Bus und Diagnostics.

### Migrationshinweise

```text
docs/migration/
```

Es wurden keine bisherigen Exports oder SDK-v1-Methoden entfernt.


## Ecosystem & Integration – v0.7.2

### Standardisierte JSON-Ausgabe

```lua
local payload = exports['airops_weather']:GetJSON()
local document = exports['airops_weather']:GetJSONDocument()
local schema = exports['airops_weather']:GetJSONSchema()
```

### Push-basierte Integrationen

```lua
local AirOps = exports['airops_weather']:GetSDK(1)

local listenerId = AirOps:Subscribe('warningAdded', function(warning)
    print(warning.code, warning.message)
end)
```

Dadurch müssen Integrationen den Wetterstatus nicht fortlaufend pollen.

### Discord-Webhooks

Webhooks sind standardmäßig deaktiviert:

```lua
Config.Webhooks.enabled = true
Config.Webhooks.url = 'YOUR_DISCORD_WEBHOOK_URL'
```

Unterstützt werden Meldungen für Start, Stopp, Provider-Ausfall,
Provider-Wiederherstellung, schwere Wetterwarnungen und kritische
Flugbedingungen. Die interne Queue bietet Rate-Limiting und Retry-Logik.

### Integration Metrics

```lua
local metrics =
    exports['airops_weather']:GetIntegrationMetrics()
```

Erfasst werden unter anderem Events, Listener, JSON-Exporte, Webhook-Erfolge,
Fehler, Retries und verworfene Nachrichten.

### Dokumentation und Beispiele

```text
docs/
examples/
assets/
```

Die mitgelieferten Beispiele zeigen eine einfache Event-Integration und eine
HEMS-Flugstatusabfrage.


## Integration SDK – v0.7.2

Die Alpha-Version führt eine versionierte SDK-Schicht ein. Bestehende Exports
bleiben vollständig erhalten.

### SDK laden

```lua
local AirOps, errorMessage =
    exports['airops_weather']:GetSDK(1)

if not AirOps then
    print(errorMessage)
    return
end
```

Ohne Versionsnummer wird die konfigurierte Standardversion verwendet:

```lua
local AirOps = exports['airops_weather']:GetSDK()
```

### SDK verwenden

Die Methoden unterstützen sowohl Punkt- als auch Doppelpunkt-Syntax:

```lua
local weather = AirOps:GetWeather()
local state = AirOps:GetState()
local forecast = AirOps:GetForecast({ hours = 6 })
local warnings = AirOps:GetWarnings()
local health = AirOps:GetHealth()
local providers = AirOps:GetProviders()
local metadata = AirOps:GetMetadata()
```

Alternativ:

```lua
local weather = AirOps.GetWeather()
```

### API-Versionierung

```lua
local apiVersion =
    exports['airops_weather']:GetAPIVersion()

local sdkVersions =
    exports['airops_weather']:GetSDKVersions()
```

Aktuell verfügbar:

```text
SDK v1
API v1
```

Neue SDK-Versionen können später parallel ergänzt werden, ohne Integrationen
auf Basis von SDK v1 zu beschädigen.

### Zonen-Grundlage

Die API akzeptiert bereits optional eine Zone:

```lua
local weather = AirOps:GetWeather({
    zone = 'default'
})
```

In dieser Alpha-Version existiert ausschließlich:

```text
default
```

Unbekannte Zonen liefern `nil` und eine eindeutige Fehlermeldung. Dadurch ist
die Schnittstelle bereits für spätere Wetterzonen vorbereitet, ohne das
bestehende globale Wetterverhalten zu verändern.

## Provider Framework – v0.7.2

Provider werden über eine gemeinsame Schnittstelle registriert. Der Scheduler
kennt keine provider-spezifische Implementierung mehr.

Mitgelieferte Provider:

```text
openmeteo
mock
```

### Provider auswählen

```lua
Config.Provider.name = 'openmeteo'
```

Für lokale Entwicklung und reproduzierbare Tests:

```lua
Config.Provider.name = 'mock'
```

Die Werte des Mock-Providers werden über `Config.MockProvider` gesteuert.

### Registrierte Provider abrufen

```lua
local providers =
    exports['airops_weather']:GetRegisteredProviders()
```

Oder über das SDK:

```lua
local providers = AirOps:GetProviders()
```

### Provider-Vertrag

Ein Provider registriert mindestens eine `fetch(callback)`-Funktion:

```lua
AirOpsWeather.Providers.Register('example', {
    displayName = 'Example Provider',
    version = 1,

    fetch = function(callback)
        callback(true, {
            timezoneOffsetSeconds = 0,
            current = {},
            forecast = {}
        })

        return true
    end
})
```

Der Provider muss genau einmal über den Callback abschließen. Mehrfache
Callbacks werden erkannt und ignoriert.


## Diagnostics & Admin Tools

v0.6.0 erweitert AirOps um ein frameworkfreies Health-, Logging- und
Diagnosesystem.

### Health-Status

```lua
local health = exports['airops_weather']:GetHealth()
```

Mögliche Zustände:

```text
HEALTHY
DEGRADED
UNHEALTHY
```

Beispiel:

```lua
{
    status = 'DEGRADED',
    provider = {
        available = false,
        lastError = 'HTTP 500',
        consecutiveFailures = 3
    },
    cache = {
        valid = true,
        stale = true,
        ageSeconds = 1900
    },
    issues = {
        {
            code = 'PROVIDER_UNAVAILABLE',
            severity = 'warning'
        }
    }
}
```

### Vollständiger Diagnose-Snapshot

```lua
local diagnostics =
    exports['airops_weather']:GetDiagnostics()
```

Der Snapshot enthält:

- Health-Status
- aktuellen API-Zustand
- Performance-Metriken
- Forecast-Diagnose
- Integrationsstatus
- Ergebnis der Konfigurationsvalidierung
- sichere Konfigurationsübersicht ohne Zugangsdaten

Weitere Exports:

```lua
exports['airops_weather']:GetIntegrations()
exports['airops_weather']:GetForecastDiagnostics()
exports['airops_weather']:ValidateConfiguration()
```

### Konsolenbefehle

```text
airops_weather_status
airops_weather_health
airops_weather_forecast
airops_weather_metrics
airops_weather_integrations
```

### Befehle im Spiel

```text
/airops status
/airops health
/airops forecast
/airops warnings
/airops metrics
/airops integrations
```

Für Diagnosebefehle wird benötigt:

```cfg
add_ace group.admin airops.weather.status allow
```

### Konfigurationsvalidierung

Beim Start werden unter anderem geprüft:

- Koordinaten
- Provider
- Forecast-Dauer
- Polling- und Retry-Werte
- Wetterzuordnungen
- Warn- und Fluggrenzwerte
- Natural-Disasters-Konfiguration
- widersprüchliche Schwellenwerte

Bei kritischen Konfigurationsfehlern wird der Provider-Start blockiert. Die
Fehler werden eindeutig mit Code und Beschreibung ausgegeben.

### Logging

```lua
Config.Logging = {
    level = 'INFO',
    suppressRepeatedMessages = true,
    repeatWindowSeconds = 300,
    repeatSummaryThreshold = 2
}
```

Verfügbare Stufen:

```text
ERROR
WARN
INFO
DEBUG
TRACE
```

Wiederholte identische Meldungen werden zusammengefasst, um Konsolen-Spam bei
Provider- oder Integrationsausfällen zu vermeiden.

### Provider- und Health-Events

```lua
AddEventHandler('airops_weather:providerUnavailable', function(data)
    print(data.reason)
end)

AddEventHandler('airops_weather:providerRecovered', function(data)
    print(data.previousError)
end)

AddEventHandler(
    'airops_weather:healthChanged',
    function(oldStatus, newStatus, health)
        print(oldStatus, newStatus)
    end
)
```


## Public API

Seit v0.5.0 macht AirOps sich als zentrale Wetter- und Zeitquelle für andere Ressourcen nutzbar.
Die API-Version innerhalb der Rückgabewerte lautet aktuell `1`.

### Server-Exports

```lua
local weather = exports['airops_weather']:GetWeather()
local time = exports['airops_weather']:GetTime()
local state = exports['airops_weather']:GetState()
local forecast = exports['airops_weather']:GetForecast(12)
local flight = exports['airops_weather']:GetFlightConditions()
local warnings = exports['airops_weather']:GetWarnings()
```

Kleingeschriebene Aliase wie `getWeather()` bleiben ebenfalls verfügbar.

### Wetterprofil

```lua
local profile = exports['airops_weather']:GetWeather()
```

Beispielstruktur:

```lua
{
    apiVersion = 1,
    resourceVersion = '0.7.2',
    weather = 'RAIN',
    class = 'precipitation',
    intensity = 0.42,
    temperatureCelsius = 18.2,
    humidityPercent = 84,
    pressureHpa = 1008,
    precipitationMm = 2.1,
    cloudCoverPercent = 92,
    visibilityMeters = 7000,
    wind = {
        speedKmh = 22,
        gustsKmh = 35,
        directionDegrees = 180
    },
    road = {
        condition = 'WET',
        recommendedSpeedFactor = 0.85
    },
    flight = {
        category = 'YELLOW',
        flyable = true,
        reasons = { 'precipitation' }
    },
    warnings = {}
}
```

Mögliche Straßenbedingungen:

```text
DRY
DAMP
WET
SNOW
FLOODED
```

Mögliche Flugkategorien:

```text
GREEN
YELLOW
ORANGE
RED
```

`flyable` ist nur eine technische Bewertung anhand der konfigurierten Grenzwerte.
Die endgültige Entscheidung bleibt bei der verwendenden Ressource beziehungsweise
dem RP-Personal.

### Forecast

```lua
local forecast = exports['airops_weather']:GetForecast(6)
```

Die Community Edition stellt maximal die intern gehaltenen zwölf Stunden bereit.
Die Rückgabe enthält die flexible AirOps-Timeline einschließlich Zwischenstufen,
Zielzeit, Provider-Zeitpunkt und meteorologischen Werten.

### Events

Andere Server-Ressourcen können ohne Polling reagieren:

```lua
AddEventHandler('airops_weather:weatherChanged', function(oldWeather, newWeather, source)
    print(oldWeather, newWeather, source)
end)

AddEventHandler('airops_weather:profileChanged', function(profile)
    print(profile.weather, profile.temperatureCelsius)
end)

AddEventHandler('airops_weather:forecastChanged', function(forecast)
    print(('Forecast entries: %d'):format(#forecast))
end)

AddEventHandler('airops_weather:warningsChanged', function(warnings)
    print(('Warnings: %d'):format(#warnings))
end)

AddEventHandler('airops_weather:overrideStarted', function(scope, overrideState)
    print(('Override started: %s'):format(scope))
end)

AddEventHandler('airops_weather:overrideEnded', function(scope, reason, overrideState)
    print(('Override ended: %s'):format(scope))
end)
```

Zusätzlich wird `airops_weather:stateChanged` mit dem vollständigen API-Zustand
ausgelöst.

### Client-Exports

Client-Ressourcen greifen auf den zuletzt vom Server synchronisierten Zustand zu:

```lua
local weather = exports['airops_weather']:GetCurrentWeather()
local time = exports['airops_weather']:GetCurrentTime()
local state = exports['airops_weather']:GetCurrentState()
```

Client-Event:

```lua
AddEventHandler('airops_weather:client:stateChanged', function(state)
    print(state.currentWeather)
end)
```

Die Client-API führt keine eigenen HTTP-Anfragen aus.

### Konfiguration der Bewertungen

```lua
Config.API = {
    enabled = true,
    emitEvents = true,
    enableClientExports = true,
    warnings = {
        strongWindKmh = 35,
        severeWindKmh = 55,
        lowVisibilityMeters = 3000,
        criticalVisibilityMeters = 1200,
        heavyPrecipitationMm = 4.0,
        extremePrecipitationMm = 8.0
    },
    flight = {
        yellowWindKmh = 30,
        orangeWindKmh = 45,
        redWindKmh = 60,
        yellowGustKmh = 40,
        orangeGustKmh = 55,
        redGustKmh = 70,
        yellowVisibilityMeters = 5000,
        orangeVisibilityMeters = 2500,
        redVisibilityMeters = 1000
    }
}
```


## Performance und Stabilität

Seit v0.4.0 reduziert AirOps unnötige Dauerarbeit und macht den internen Zustand messbar.

### Bedingte Broadcasts

Nach einem erfolgreichen Provider-Abruf wird der vollständige Zustand nicht mehr
automatisch an alle Clients gesendet. Ein Broadcast erfolgt nur bei:

- geändertem GTA-Wetter
- relevant geänderter Windgeschwindigkeit oder Windrichtung
- relevant geänderter Temperatur
- geändertem Override-Modus
- Ablauf des Sicherheits-Heartbeats

```lua
Config.Performance = {
    suppressUnchangedBroadcasts = true,
    heartbeatBroadcastSeconds = 900,
    windChangeThresholdKmh = 2.0,
    windDirectionThresholdDegrees = 15.0,
    temperatureChangeThresholdCelsius = 1.0,
    clientWeatherReinforcementMilliseconds = 60000
}
```

Direkte Synchronisationen neu beitretender Spieler werden niemals unterdrückt.

### API-Watchdog

```lua
Config.Retry.requestTimeoutSeconds = 20
```

Antwortet der Provider nicht innerhalb des Zeitfensters, wird die Anfrage als
fehlgeschlagen gewertet. Eine verspätete Antwort wird ignoriert und kann keine
doppelte Planung oder parallele Retry-Kette auslösen.

### Cache-Ausfallsicherheit

```lua
Config.Health = {
    staleCacheSeconds = 1800,
    warnWhenCacheBecomesStale = true
}
```

Bei einem Provider-Ausfall bleibt das zuletzt bekannte Wetter aktiv. Nach dem
konfigurierten Zeitraum wird der Cache in Diagnoseausgaben als `stale` markiert.

### Diagnose

```text
airops_weather_status
```

Die Ausgabe enthält zusätzlich:

- API-Anfragen, Erfolge, Fehler und Timeouts
- letzte und durchschnittliche Antwortzeit
- globale und unterdrückte Broadcasts
- direkte Spieler-Synchronisationen
- Wetterwechsel
- Timeline-Erstellungen und ausgeführte Einträge
- Ressourcen-Uptime

Export:

```lua
local metrics = exports['airops_weather']:getPerformanceMetrics()
```


## Server-Exports

### Gesamtstatus

```lua
local state = exports['airops_weather']:getWeatherData()
```

### Provider sofort aktualisieren

```lua
exports['airops_weather']:forceWeatherUpdate()
```

### Wetter-Timeline

```lua
local timeline = exports['airops_weather']:getForecastTimeline()
```

### Wetter-Override

```lua
exports['airops_weather']:setWeatherOverride('RAIN', 30, 'event_script')
```

Parameter:

```text
weather, durationMinutes, source, transitionSeconds
```

### Zeit-Override

```lua
exports['airops_weather']:setTimeOverride(22, 30, 60, 'event_script')
```

Parameter:

```text
hour, minute, durationMinutes, source
```

### Overrides löschen

```lua
exports['airops_weather']:clearOverride('weather', 'event ended')
exports['airops_weather']:clearOverride('time', 'event ended')
exports['airops_weather']:clearOverride('all', 'event ended')
```

### Override-Status

```lua
local override = exports['airops_weather']:getOverrideState()
```

## Unterstützte Wettertypen

```text
EXTRASUNNY
CLEAR
NEUTRAL
SMOG
FOGGY
CLOUDS
OVERCAST
CLEARING
RAIN
THUNDER
SNOW
BLIZZARD
SNOWLIGHT
XMAS
HALLOWEEN
```

Die tatsächliche Darstellung einzelner Wettertypen hängt von GTA V sowie möglicherweise von anderen Grafik- oder Wetterressourcen ab.

## Diagnose und Test

Providerdaten sofort neu abrufen:

```text
airops_weather_update
```

Ausführlichen Status anzeigen:

```text
airops_weather_status
```

Debugausgaben aktivieren:

```lua
Config.General.debug = true
```

Vor einem stabilen v1.0-Release werden zusätzlich Resmon-, Serverlast-, Langzeit- und Natural-Disasters-Stresstests durchgeführt.

## Bekannte Einschränkungen

- Aktuell ist nur Open-Meteo als Provider enthalten.
- Andere aktive Zeit- oder Wettersysteme können Konflikte verursachen.
- Natural Disasters wird unterstützt; weitere Wettersysteme benötigen eigene Adapter.
- Die Version 0.7.2 ist eine frühe Entwicklungsversion und noch kein finaler v1.0-Release.

Wetterdaten: Open-Meteo. Lizenzbedingungen siehe `LICENSE`.
