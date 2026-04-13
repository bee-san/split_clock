import QtQuick 2.15
import QtTest 1.2

import "../contents/ui/WeatherScene.js" as WeatherScene

TestCase {
    name: "WeatherScene"

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

    function test_localEligibilityIsRejected() {
        compare(WeatherScene.eligibleForWeather(35.6, 139.7, "Local"), false);
        compare(WeatherScene.eligibleForWeather(35.6, 139.7, "Asia/Tokyo"), true);
        compare(WeatherScene.eligibleForWeather(null, 139.7, "Asia/Tokyo"), false);
    }
}
