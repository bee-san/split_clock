import QtQuick 2.15
import QtTest 1.2

import "../contents/ui"
import "../contents/ui/WeatherScene.js" as WeatherScene

TestCase {
    id: testCase

    name: "WeatherSource"

    function createSource(properties) {
        const source = createTemporaryObject(sourceComponent, testCase, properties || {});

        verify(source !== null);
        wait(0);
        return source;
    }

    Component {
        id: sourceComponent

        WeatherSource {
            weatherEnabled: false
        }
    }

    function clearState() {
        return WeatherScene.normalizeSceneState({
            "available": true,
            "status": "ready",
            "kind": "clear",
            "cloudOpacity": 0.02,
            "cloudFamily": "none",
            "conditionLabel": "Clear sky"
        });
    }

    function stormState() {
        return WeatherScene.normalizeSceneState({
            "available": true,
            "status": "ready",
            "kind": "thunderstorm",
            "cloudOpacity": 0.9,
            "cloudFamily": "shelf",
            "rainDensity": 0.84,
            "rainBand": "downpour",
            "storminess": 0.88,
            "lightning": true,
            "conditionLabel": "Thunderstorm"
        });
    }

    function test_initialFailureFallsBackToUnavailableScene() {
        const source = createSource();

        source.handleFailure("offline");

        compare(source.fetchStatus, "error");
        compare(source.sceneState.available, false);
        compare(source.sceneState.kind, "clear");
    }

    function test_failureKeepsLastGoodScene() {
        const source = createSource();

        source.applySceneState(WeatherScene.normalizeSceneState({
            "available": true,
            "status": "ready",
            "kind": "snow",
            "snowDensity": 0.6
        }));
        source.hasFetchedOnce = true;
        source.fetchStatus = "ready";
        source.handleFailure("timeout");

        compare(source.fetchStatus, "stale");
        compare(source.sceneState.kind, "snow");
        compare(source.sceneState.available, true);
    }

    function test_secondMeaningfulSceneStartsVisualTransition() {
        const source = createSource();

        source.applySceneState(clearState());
        source.hasFetchedOnce = true;
        source.applySceneState(stormState());

        compare(source.visualTransitionActive, true);
        compare(source.sceneState.kind, "thunderstorm");
        compare(source.transitionFromSceneState.kind, "clear");
        compare(source.transitionToSceneState.kind, "thunderstorm");
        verify(source.visualTransitionProgress < 0.1);
    }

    function test_stepTransitionBlendsAndCompletes() {
        const source = createSource();

        source.applySceneState(clearState());
        source.hasFetchedOnce = true;
        source.applySceneState(stormState());
        source.stepTransition(source.sceneTransitionDurationMs / 2);

        verify(source.displaySceneState.cloudOpacity > source.transitionFromSceneState.cloudOpacity);
        verify(source.displaySceneState.cloudOpacity < source.transitionToSceneState.cloudOpacity);
        source.stepTransition(source.sceneTransitionDurationMs);

        compare(source.visualTransitionActive, false);
        compare(source.visualTransitionProgress, 1);
        compare(source.displaySceneState.kind, "thunderstorm");
        compare(source.displaySceneState.lightning, true);
    }

    function test_buildRequestUrlIncludesCoordinatesAndTimezone() {
        const source = createSource({
            "latitude": 35.654444,
            "longitude": 139.744722,
            "timeZoneId": "Asia/Tokyo"
        });
        const url = source.buildRequestUrl();

        verify(url.indexOf("latitude=35.654444") !== -1);
        verify(url.indexOf("longitude=139.744722") !== -1);
        verify(url.indexOf("timezone=Asia%2FTokyo") !== -1);
        verify(url.indexOf("current=") !== -1);
        verify(url.indexOf("relative_humidity_2m") !== -1);
        verify(url.indexOf("daily=apparent_temperature_max") !== -1);
        verify(url.indexOf("temperature_unit=celsius") !== -1);
        verify(url.indexOf("forecast_days=1") !== -1);
    }

    function test_canFetchRejectsLocal() {
        const localSource = createSource({
            "weatherEnabled": true,
            "latitude": 35.654444,
            "longitude": 139.744722,
            "timeZoneId": "Local"
        });
        const remoteSource = createSource({
            "weatherEnabled": true,
            "latitude": 35.654444,
            "longitude": 139.744722,
            "timeZoneId": "Asia/Tokyo"
        });

        compare(localSource.canFetch(), false);
        compare(remoteSource.canFetch(), true);
    }

    function test_applyDailyMetricsStoresMaxFeelsLike() {
        const source = createSource();

        source.applyDailyMetrics({
            "daily": {
                "apparent_temperature_max": [31.4]
            }
        });

        compare(source.maxFeelsLikeTemperatureCelsius, 31.4);
    }

    function test_derivedSceneStateAddsPostRainClearing() {
        const source = createSource();
        const clearScene = WeatherScene.normalizeSceneState({
            "available": true,
            "status": "ready",
            "kind": "clear",
            "cloudOpacity": 0.02,
            "cloudFamily": "none",
            "conditionLabel": "Clear sky"
        });
        const nowMs = 1000000;

        source.lastRainTimestampMs = nowMs;

        const derived = source.derivedSceneStateForRaw(clearScene, nowMs + (source.postRainClearingDurationMs * 0.2));

        compare(derived.conditionLabel, "Clearing after rain");
        verify(derived.clearingStrength > 0.75);
        verify(derived.cloudOpacity > clearScene.cloudOpacity);
        verify(derived.humidityHaze > 0.2);
    }
}
