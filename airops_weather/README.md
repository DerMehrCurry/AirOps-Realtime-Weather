# AirOps Realtime Weather – Community Edition

Core-unabhängige Echtzeit-Wetter- und Zeitsynchronisation für FiveM.

> Die Community Edition ist kostenlos. Wenn du dafür bei einem Drittanbieter bezahlt hast, wurdest du getäuscht.

## Version 0.5.0

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



## Public API

v0.5.0 macht AirOps zur zentralen Wetter- und Zeitquelle für andere Ressourcen.
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
    resourceVersion = '0.5.0',
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

v0.4.0 reduziert unnötige Dauerarbeit und macht den internen Zustand messbar.

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
- Die Version 0.3.0 ist weiterhin eine Entwicklungsversion und noch kein finaler v1.0-Release.

Wetterdaten: Open-Meteo. Lizenzbedingungen siehe `LICENSE`.
