# AGENTS.md

## Scope
This repo is a KDE Plasma plasmoid (`dev.bee.splitclock`) built with QML.

## Testing
Run QML tests from the repo root.

### Weather tests that work with the current local toolchain
These run under the available `qmltestrunner` binary.

```bash
QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/tst_weatherscene.qml
QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/tst_weathersource.qml
```

### Known caveat
`tests/tst_weatheroverlay.qml` currently aborts in this environment with exit code `134` instead of reporting a normal test failure.

```bash
QT_QPA_PLATFORM=offscreen qmltestrunner -input tests/tst_weatheroverlay.qml
```

### Qt 6 rendering checks
This plasmoid uses Qt 6 style imports in files like `contents/ui/TimeCard.qml`.
For ad hoc rendering or screenshot capture, use `qmlscene6`, not the Qt 5 `qmlscene` binary.

Example:

```bash
QT_QPA_PLATFORM=offscreen qmlscene6 /tmp/render_split_clock_rain.qml
```

## Packaging and reload
Upgrade the installed local plasmoid from the working tree:

```bash
kpackagetool6 -t Plasma/Applet -u /home/bee/Documents/src/github/split_clock
```

If Plasma Shell is running, restart it through the user service:

```bash
systemctl --user restart plasma-plasmashell.service
```

If the desktop is black because `plasmashell` is down, start it again with:

```bash
systemctl --user start plasma-plasmashell.service
```

Check status with:

```bash
systemctl --user status plasma-plasmashell.service
```

## Weather behavior notes
- Remote weather is fetched from Open-Meteo.
- Dominant-day weather now comes from hourly forecast aggregation when hourly data is present.
- Retry backoff is currently `5s`, `1m`, `5m`, `10m`, `30m`.
- On an initial fetch failure before any successful weather response, max temperature can disappear because the stored value is reset to `NaN`.

## Protected UI elements
Hard rule: never, under any circumstances, remove or alter the core text/UI elements on the card.

Protected elements:
- city
- time
- max temperature
- feels like temperature
- weather emoji

This includes removing them, hiding them, renaming them, changing their wording, or otherwise touching them during weather visual work.

## Useful files
- `contents/ui/WeatherScene.js`: weather classification and scene generation.
- `contents/ui/WeatherSource.qml`: fetch, retry, and scene state application.
- `contents/ui/TimeCard.qml`: card rendering and weather visuals.
- `tests/tst_weatherscene.qml`: scene logic coverage.
- `tests/tst_weathersource.qml`: source/retry/transition coverage.
