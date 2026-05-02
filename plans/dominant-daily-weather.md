# Dominant Daily Weather Scene

## Summary
Change weather rendering so each remote card uses the dominant weather for the full local day, not just `current.*`, and let that dominant result drive the full scene and weather glyph/label.

The dominant result will always win when it disagrees with current weather. Example: if today has a long rain block and clear weather right now, the card still renders as rain.

## Implementation Changes
- Extend the Open-Meteo request in `WeatherSource.qml` to include `hourly=time,weather_code,is_day,precipitation,rain,showers,snowfall,cloud_cover,relative_humidity_2m,wind_speed_10m,wind_direction_10m` while keeping the existing `daily=apparent_temperature_max`.
- Keep `WeatherScene.sceneStateFromApiResponse(apiResponse)` as the entrypoint, but change its behavior:
  - If `hourly.*` is present and valid, derive a dominant-day representative sample from the full local day.
  - If hourly data is missing or malformed, fall back to the current behavior using `apiResponse.current`.
- Dominant-day selection algorithm:
  - Use all hourly samples for the card’s local calendar day from the API response.
  - Map each hourly sample to a weather kind using the existing weather-code logic.
  - Pick the winning kind by hour count across the day.
  - On ties, use this severity order: `thunderstorm > snow > rain > fog > cloudy > clear`.
- Build the representative sample for the winning kind from only the hourly samples in that kind:
  - `weather_code`: modal code within the winning kind; ties use the same severity order.
  - `precipitation`, `rain`, `showers`, `snowfall`, `cloud_cover`, `relative_humidity_2m`, `wind_speed_10m`, `wind_direction_10m`: arithmetic mean across winning samples.
  - `is_day`: take from `apiResponse.current.is_day` so day/night-only weather shading still matches the actual current time.
  - `time`/observation marker: use `apiResponse.current.time`.
- Feed that representative sample through the existing `sceneStateFromCurrentData(...)` path so all existing cloud/rain/snow/fog tuning remains consistent.
- Keep `maxFeelsLikeTemperatureCelsius` exactly as it is now from `daily.apparent_temperature_max`.
- Disable post-rain-clearing chronology effects for dominant-day scenes, because that effect depends on observed sequence over time and becomes misleading once the scene is forecast-aggregated for the whole day.

## Interfaces
- No user-facing config change.
- Internal request contract changes:
  - `WeatherSource.buildRequestUrl()` now requests hourly forecast fields in addition to the current and daily fields.
- Internal scene API behavior changes:
  - `WeatherScene.sceneStateFromApiResponse(apiResponse)` becomes dominant-day when hourly exists, current-only fallback otherwise.

## Test Plan
- `tests/tst_weathersource.qml`
  - Verify the request URL now includes the `hourly=` fields.
  - Verify `daily=apparent_temperature_max` remains requested.
  - Verify daily max-feels-like extraction is unchanged.
- `tests/tst_weatherscene.qml`
  - Add a case where `current` is clear but the day has many rain hours; expect `sceneStateFromApiResponse(...)` to return a rain scene.
  - Add a case where hourly counts tie; expect the severity tie-break to choose the higher-impact kind.
  - Add a case where the dominant kind is cloudy/clear and ensure it does not inject “Clearing after rain”.
  - Add a fallback case where `hourly` is absent and the existing current-based behavior remains intact.
- Optional card-level coverage:
  - Add one `TimeCard`/`WeatherSource` integration test that proves the visible weather glyph/scene follows dominant-day output rather than current conditions.

## Assumptions
- “Today” means the full local calendar day for the card’s configured timezone, not just remaining hours.
- The card should visually represent the dominant day result even when current weather differs.
- Hourly slots are weighted equally by duration.
- If dominant kind is selected, the scene should look representative rather than “peak worst hour”; averaging within the winning kind is the default.
