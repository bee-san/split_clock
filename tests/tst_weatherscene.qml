import QtQuick 2.15
import QtTest 1.2

import "../contents/ui/WeatherScene.js" as WeatherScene

TestCase {
    name: "WeatherScene"

    function dominantDayResponse(overrides) {
        const response = {
            "current": {
                "time": "2026-04-15T12:00",
                "is_day": 1,
                "weather_code": 0,
                "cloud_cover": 12,
                "relative_humidity_2m": 54
            },
            "hourly": {
                "time": [
                    "2026-04-15T00:00",
                    "2026-04-15T03:00",
                    "2026-04-15T06:00",
                    "2026-04-15T09:00",
                    "2026-04-15T12:00",
                    "2026-04-15T15:00"
                ],
                "weather_code": [0, 0, 63, 63, 63, 63],
                "is_day": [0, 0, 1, 1, 1, 1],
                "precipitation": [0, 0, 1.8, 2.2, 2.4, 2.0],
                "rain": [0, 0, 1.6, 2.0, 2.2, 1.8],
                "showers": [0, 0, 0.2, 0.2, 0.2, 0.2],
                "snowfall": [0, 0, 0, 0, 0, 0],
                "cloud_cover": [8, 12, 88, 92, 94, 90],
                "relative_humidity_2m": [48, 50, 78, 82, 84, 80],
                "wind_speed_10m": [6, 7, 16, 18, 20, 17],
                "wind_direction_10m": [90, 90, 135, 140, 145, 150]
            }
        };

        if (!overrides) {
            return response;
        }

        if (overrides.current) {
            response.current = overrides.current;
        }

        if (overrides.hourly) {
            response.hourly = overrides.hourly;
        }

        return response;
    }

    function test_clearCodeStaysClear() {
        const scene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 0,
            "cloud_cover": 8,
            "is_day": 1
        });

        compare(scene.kind, "clear");
        compare(scene.available, true);
        verify(scene.cloudOpacity < 0.05);
    }

    function test_cloudOnlyCodesScaleFromLightToOvercast() {
        const lightClouds = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 1,
            "cloud_cover": 28,
            "is_day": 1
        });
        const overcast = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 3,
            "cloud_cover": 100,
            "is_day": 1
        });

        compare(lightClouds.kind, "cloudy");
        compare(overcast.kind, "cloudy");
        compare(lightClouds.cloudFamily, "wispy");
        compare(overcast.cloudFamily, "stratus");
        verify(lightClouds.cloudBandCount < overcast.cloudBandCount);
        verify(lightClouds.cloudBreakFactor > overcast.cloudBreakFactor);
        verify(lightClouds.celestialVeilOpacity < overcast.celestialVeilOpacity);
    }

    function test_brokenCloudsCastStrongerShadowsThanOvercast() {
        const brokenClouds = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 2,
            "cloud_cover": 58,
            "is_day": 1
        });
        const overcast = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 3,
            "cloud_cover": 100,
            "is_day": 1
        });

        verify(brokenClouds.cloudShadowStrength > 0.2);
        verify(overcast.cloudShadowStrength < brokenClouds.cloudShadowStrength);
    }

    function test_fogCodeBuildsFogScene() {
        const scene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 45,
            "cloud_cover": 92,
            "is_day": 0
        });

        compare(scene.kind, "fog");
        verify(scene.fogOpacity > 0.4);
        verify(scene.starVisibilityFactor < 0.45);
    }

    function test_rainCodeBuildsRainScene() {
        const scene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 63,
            "rain": 2.6,
            "precipitation": 2.8,
            "cloud_cover": 94,
            "is_day": 0
        });

        compare(scene.kind, "rain");
        verify(scene.rainDensity > 0.4);
        verify(scene.cloudOpacity > 0.5);
    }

    function test_humidityBuildsHazeAndBloom() {
        const scene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 0,
            "cloud_cover": 12,
            "relative_humidity_2m": 89,
            "is_day": 1
        });

        compare(scene.kind, "clear");
        verify(scene.humidity > 0.85);
        verify(scene.humidityHaze > 0.1);
        verify(scene.humidityBloom > 0.08);
    }

    function test_rainBandsSeparateDrizzleFromDownpour() {
        const drizzle = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 51,
            "rain": 0.2,
            "precipitation": 0.2,
            "cloud_cover": 76,
            "is_day": 1
        });
        const downpour = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 82,
            "rain": 4.4,
            "precipitation": 4.8,
            "cloud_cover": 98,
            "wind_speed_10m": 28,
            "is_day": 1
        });

        compare(drizzle.rainBand, "drizzle");
        compare(downpour.rainBand, "downpour");
        verify(drizzle.orbOcclusionOpacity < downpour.orbOcclusionOpacity);
        verify(drizzle.fogDepth < downpour.fogDepth);
    }

    function test_snowCodeBuildsSnowScene() {
        const scene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 75,
            "snowfall": 2.2,
            "cloud_cover": 88,
            "is_day": 1
        });

        compare(scene.kind, "snow");
        verify(scene.snowDensity > 0.6);
        verify(scene.coolTint > 0.3);
    }

    function test_snowBandsSeparateFlurriesFromHeavy() {
        const flurries = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 71,
            "snowfall": 0.3,
            "cloud_cover": 72,
            "is_day": 1
        });
        const heavy = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 75,
            "snowfall": 2.8,
            "cloud_cover": 92,
            "wind_speed_10m": 18,
            "is_day": 1
        });

        compare(flurries.snowBand, "flurries");
        compare(heavy.snowBand, "heavy");
        verify(flurries.orbOcclusionOpacity < heavy.orbOcclusionOpacity);
        verify(flurries.fogDepth < heavy.fogDepth);
    }

    function test_thunderstormCodeBuildsStormScene() {
        const scene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 95,
            "rain": 3.4,
            "precipitation": 3.6,
            "wind_speed_10m": 38,
            "cloud_cover": 100,
            "is_day": 0
        });

        compare(scene.kind, "thunderstorm");
        compare(scene.cloudFamily, "shelf");
        compare(scene.lightning, true);
        verify(scene.storminess > 0.7);
        verify(scene.starVisibilityFactor === 0);
    }

    function test_stormWindTightensMotionAndLightningCadence() {
        const calmerStorm = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 95,
            "rain": 2.8,
            "precipitation": 3.1,
            "wind_speed_10m": 12,
            "wind_direction_10m": 90,
            "cloud_cover": 100,
            "is_day": 0
        });
        const windierStorm = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 95,
            "rain": 2.8,
            "precipitation": 3.1,
            "wind_speed_10m": 36,
            "wind_direction_10m": 90,
            "cloud_cover": 100,
            "is_day": 0
        });

        verify(windierStorm.cloudSpeed > calmerStorm.cloudSpeed);
        verify(windierStorm.lightningCadence < calmerStorm.lightningCadence);
    }

    function test_postRainClearingKeepsResidualMoisture() {
        const clearScene = WeatherScene.sceneStateFromCurrentData({
            "weather_code": 0,
            "cloud_cover": 10,
            "relative_humidity_2m": 62,
            "is_day": 1
        });
        const clearingScene = WeatherScene.applyPostRainClearing(clearScene, 0.72);

        compare(clearingScene.kind, "clear");
        compare(clearingScene.conditionLabel, "Clearing after rain");
        verify(clearingScene.clearingStrength > 0.7);
        verify(clearingScene.cloudOpacity > clearScene.cloudOpacity);
        verify(clearingScene.humidityHaze > clearScene.humidityHaze);
        verify(clearingScene.fogDepth > clearScene.fogDepth);
    }

    function test_apiResponseUsesDominantDayKindOverCurrentWeather() {
        const scene = WeatherScene.sceneStateFromApiResponse(dominantDayResponse());

        compare(scene.kind, "rain");
        compare(scene.conditionLabel, "Rain");
        compare(scene.rawWeatherCode, 63);
        compare(scene.observationTime, "2026-04-15T12:00");
        compare(scene.isDay, true);
        compare(scene.postRainClearingEligible, false);
        verify(scene.rainDensity > 0.35);
    }

    function test_apiResponseBreaksHourlyTiesBySeverity() {
        const scene = WeatherScene.sceneStateFromApiResponse(dominantDayResponse({
            "hourly": {
                "time": [
                    "2026-04-15T00:00",
                    "2026-04-15T03:00",
                    "2026-04-15T06:00",
                    "2026-04-15T09:00"
                ],
                "weather_code": [63, 63, 75, 75],
                "is_day": [0, 0, 1, 1],
                "precipitation": [1.8, 2.0, 1.8, 1.9],
                "rain": [1.8, 2.0, 0, 0],
                "showers": [0, 0, 0, 0],
                "snowfall": [0, 0, 1.8, 2.0],
                "cloud_cover": [92, 94, 96, 98],
                "relative_humidity_2m": [84, 86, 88, 90],
                "wind_speed_10m": [18, 20, 16, 17],
                "wind_direction_10m": [120, 125, 130, 135]
            }
        }));

        compare(scene.kind, "snow");
        compare(scene.conditionLabel, "Snow");
        compare(scene.rawWeatherCode, 75);
        compare(scene.postRainClearingEligible, false);
    }

    function test_apiResponseLetsMeaningfulRainBeatGenericCloudCover() {
        const scene = WeatherScene.sceneStateFromApiResponse(dominantDayResponse({
            "hourly": {
                "time": [
                    "2026-04-15T00:00",
                    "2026-04-15T01:00",
                    "2026-04-15T02:00",
                    "2026-04-15T03:00",
                    "2026-04-15T04:00",
                    "2026-04-15T05:00",
                    "2026-04-15T06:00",
                    "2026-04-15T07:00",
                    "2026-04-15T08:00",
                    "2026-04-15T09:00",
                    "2026-04-15T10:00",
                    "2026-04-15T11:00",
                    "2026-04-15T12:00",
                    "2026-04-15T13:00",
                    "2026-04-15T14:00",
                    "2026-04-15T15:00",
                    "2026-04-15T16:00",
                    "2026-04-15T17:00",
                    "2026-04-15T18:00",
                    "2026-04-15T19:00",
                    "2026-04-15T20:00",
                    "2026-04-15T21:00",
                    "2026-04-15T22:00",
                    "2026-04-15T23:00"
                ],
                "weather_code": [3,3,3,3,3,3,3,3,51,3,3,3,51,51,3,3,53,53,1,1,1,0,2,0],
                "is_day": [0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
                "precipitation": [0,0,0,0,0,0,0,0,0.1,0,0,0,0.3,0.1,0,0,0.5,0.8,0,0,0,0,0,0],
                "rain": [0,0,0,0,0,0,0,0,0.1,0,0,0,0.3,0.1,0,0,0.5,0.8,0,0,0,0,0,0],
                "showers": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                "snowfall": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                "cloud_cover": [100,100,100,100,100,100,100,100,100,100,100,100,100,100,90,97,100,100,26,27,24,2,51,2],
                "relative_humidity_2m": [88,88,88,88,88,88,88,88,92,88,88,88,94,92,88,88,94,96,72,70,68,60,66,58],
                "wind_speed_10m": [14,14,14,14,14,14,14,14,16,14,14,14,16,16,14,14,18,20,10,10,9,8,10,8],
                "wind_direction_10m": [186,186,186,186,186,186,186,186,190,186,186,186,194,194,186,186,200,202,180,180,178,170,176,168]
            }
        }));

        compare(scene.kind, "rain");
        compare(scene.conditionLabel, "Rain");
        compare(scene.rawWeatherCode, 61);
        compare(scene.rainBand, "steady");
        compare(scene.outsideHoursSignalKind, "rain");
        compare(scene.outsideHoursSignalLabel, "Rain");
        compare(scene.postRainClearingEligible, false);
    }

    function test_apiResponsePrioritizesRainDuringOutsideHours() {
        const scene = WeatherScene.sceneStateFromApiResponse(dominantDayResponse({
            "current": {
                "time": "2026-04-15T09:00",
                "is_day": 1,
                "weather_code": 51,
                "cloud_cover": 100
            },
            "hourly": {
                "time": [
                    "2026-04-15T00:00",
                    "2026-04-15T01:00",
                    "2026-04-15T02:00",
                    "2026-04-15T03:00",
                    "2026-04-15T04:00",
                    "2026-04-15T05:00",
                    "2026-04-15T06:00",
                    "2026-04-15T07:00",
                    "2026-04-15T08:00",
                    "2026-04-15T09:00",
                    "2026-04-15T10:00",
                    "2026-04-15T11:00",
                    "2026-04-15T12:00",
                    "2026-04-15T13:00",
                    "2026-04-15T14:00",
                    "2026-04-15T15:00"
                ],
                "weather_code": [3,3,3,3,3,3,3,3,51,51,53,1,1,1,1,1],
                "is_day": [0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1],
                "precipitation": [0,0,0,0,0,0,0,0,0.2,0.3,0.6,0,0,0,0,0],
                "rain": [0,0,0,0,0,0,0,0,0.2,0.3,0.6,0,0,0,0,0],
                "showers": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                "snowfall": [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
                "cloud_cover": [100,100,100,100,100,100,100,100,100,100,100,30,26,24,22,20],
                "relative_humidity_2m": [88,88,88,88,88,88,88,88,94,95,96,72,70,68,66,64],
                "wind_speed_10m": [12,12,12,12,12,12,12,12,14,15,18,10,10,9,8,8],
                "wind_direction_10m": [180,180,180,180,180,180,180,180,188,190,194,170,170,168,166,164]
            }
        }));

        compare(scene.kind, "rain");
        compare(scene.conditionLabel, "Rain");
        compare(scene.postRainClearingEligible, false);
    }

    function test_apiResponseForecastAggregateMarksClearAndCloudyAsNonClearing() {
        const scene = WeatherScene.sceneStateFromApiResponse(dominantDayResponse({
            "current": {
                "time": "2026-04-15T21:00",
                "is_day": 0,
                "weather_code": 63,
                "cloud_cover": 94
            },
            "hourly": {
                "time": [
                    "2026-04-15T00:00",
                    "2026-04-15T03:00",
                    "2026-04-15T06:00",
                    "2026-04-15T09:00"
                ],
                "weather_code": [2, 2, 2, 0],
                "is_day": [0, 0, 1, 1],
                "precipitation": [0, 0, 0, 0],
                "rain": [0, 0, 0, 0],
                "showers": [0, 0, 0, 0],
                "snowfall": [0, 0, 0, 0],
                "cloud_cover": [64, 68, 60, 10],
                "relative_humidity_2m": [68, 70, 66, 54],
                "wind_speed_10m": [8, 9, 10, 6],
                "wind_direction_10m": [180, 185, 190, 160]
            }
        }));

        compare(scene.kind, "cloudy");
        compare(scene.conditionLabel, "Cloudy");
        compare(scene.isDay, false);
        compare(scene.postRainClearingEligible, false);
    }

    function test_apiResponseFallsBackToCurrentWhenHourlyIsMissing() {
        const scene = WeatherScene.sceneStateFromApiResponse({
            "current": {
                "time": "2026-04-15T12:00",
                "weather_code": 95,
                "rain": 3.2,
                "precipitation": 3.6,
                "wind_speed_10m": 32,
                "cloud_cover": 100,
                "is_day": 1
            }
        });

        compare(scene.kind, "thunderstorm");
        compare(scene.conditionLabel, "Thunderstorm");
        compare(scene.postRainClearingEligible, true);
    }

    function test_localEligibilityIsRejected() {
        compare(WeatherScene.eligibleForWeather(35.6, 139.7, "Local"), false);
        compare(WeatherScene.eligibleForWeather(35.6, 139.7, "Asia/Tokyo"), true);
        compare(WeatherScene.eligibleForWeather(null, 139.7, "Asia/Tokyo"), false);
    }
}
