# AirOps Realtime Weather – Community Edition

Core-unabhängige Echtzeit-Wetter- und Zeitsynchronisation für FiveM.

> Die Community Edition ist kostenlos. Wenn du dafür bei einem Drittanbieter bezahlt hast, wurdest du getäuscht.

## Version 0.3.0

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
