import QtQuick 2.15

import "WeatherScene.js" as WeatherScene

Item {
    id: root

    visible: false

    property real latitude: NaN
    property real longitude: NaN
    property string timeZoneId: ""
    property bool weatherEnabled: true
    property int refreshIntervalMs: 10 * 60 * 1000
    property var sceneState: WeatherScene.defaultSceneState()
    property var rawSceneState: WeatherScene.defaultSceneState()
    property var displaySceneState: WeatherScene.defaultSceneState()
    property var transitionFromSceneState: WeatherScene.defaultSceneState()
    property var transitionToSceneState: WeatherScene.defaultSceneState()
    property bool visualTransitionActive: false
    property real visualTransitionProgress: 1
    property int sceneTransitionDurationMs: 1400
    property int postRainClearingDurationMs: 75 * 60 * 1000
    property double lastRainTimestampMs: 0
    property int retryAttempt: -1
    property real maxFeelsLikeTemperatureCelsius: NaN
    property string fetchStatus: "idle"
    property string errorText: ""
    property string lastObservationTime: ""
    property bool hasFetchedOnce: false
    readonly property int baseRefreshIntervalMs: {
        const configuredInterval = Number(root.refreshIntervalMs);

        return isFinite(configuredInterval) && configuredInterval > 0 ? Math.max(60 * 1000, Math.round(configuredInterval)) : 600000;
    }
    readonly property var retryIntervalsMs: [
        5 * 1000,
        1 * 60 * 1000,
        5 * 60 * 1000,
        10 * 60 * 1000,
        30 * 60 * 1000
    ]

    function canFetch() {
        return weatherEnabled && WeatherScene.eligibleForWeather(latitude, longitude, timeZoneId);
    }

    function buildRequestUrl() {
        const params = [
            "latitude=" + encodeURIComponent(String(latitude)),
            "longitude=" + encodeURIComponent(String(longitude)),
            "current=weather_code,is_day,precipitation,rain,showers,snowfall,cloud_cover,relative_humidity_2m,wind_speed_10m,wind_direction_10m",
            "hourly=weather_code,is_day,precipitation,rain,showers,snowfall,cloud_cover,relative_humidity_2m,wind_speed_10m,wind_direction_10m",
            "daily=apparent_temperature_max",
            "forecast_days=1",
            "temperature_unit=celsius",
            "timezone=" + encodeURIComponent(String(timeZoneId || "auto"))
        ];

        return "https://api.open-meteo.com/v1/forecast?" + params.join("&");
    }

    function applySceneState(nextState) {
        const normalizedNextState = WeatherScene.normalizeSceneState(nextState);
        const fromSceneState = WeatherScene.normalizeSceneState(displaySceneState);
        const shouldAnimate = hasFetchedOnce
            && WeatherScene.sceneDifferenceScore(fromSceneState, normalizedNextState) >= 0.08;

        sceneState = normalizedNextState;
        lastObservationTime = normalizedNextState.observationTime || "";

        if (!shouldAnimate) {
            transitionTicker.stop();
            displaySceneState = normalizedNextState;
            transitionFromSceneState = normalizedNextState;
            transitionToSceneState = normalizedNextState;
            visualTransitionProgress = 1;
            visualTransitionActive = false;
            return;
        }

        transitionFromSceneState = fromSceneState;
        transitionToSceneState = normalizedNextState;
        displaySceneState = fromSceneState;
        visualTransitionProgress = 0;
        visualTransitionActive = true;
        transitionTicker.restart();
    }

    function applyDailyMetrics(apiResponse) {
        const response = apiResponse || {};
        const daily = response.daily || {};
        const maximums = daily.apparent_temperature_max || [];
        const maximumFeelsLike = maximums.length > 0 ? Number(maximums[0]) : NaN;

        maxFeelsLikeTemperatureCelsius = isFinite(maximumFeelsLike) ? maximumFeelsLike : NaN;
    }

    function currentClearingStrength(nowMs) {
        const referenceNow = Number(nowMs || Date.now());

        if (lastRainTimestampMs <= 0) {
            return 0;
        }

        return Math.max(0, Math.min(1, 1 - ((referenceNow - lastRainTimestampMs) / Math.max(60000, postRainClearingDurationMs))));
    }

    function derivedSceneStateForRaw(rawState, nowMs) {
        const normalizedRaw = WeatherScene.normalizeSceneState(rawState);
        const referenceNow = Number(nowMs || Date.now());

        if (!normalizedRaw.available) {
            return normalizedRaw;
        }

        if (normalizedRaw.postRainClearingEligible === false) {
            return normalizedRaw;
        }

        if (normalizedRaw.kind === "rain" || normalizedRaw.kind === "thunderstorm") {
            return normalizedRaw;
        }

        const clearingStrength = currentClearingStrength(referenceNow);

        if ((normalizedRaw.kind === "clear" || normalizedRaw.kind === "cloudy") && clearingStrength > 0.02) {
            return WeatherScene.applyPostRainClearing(normalizedRaw, clearingStrength);
        }

        return normalizedRaw;
    }

    function applyRawSceneState(nextRawState, nowMs) {
        const normalizedRaw = WeatherScene.normalizeSceneState(nextRawState);
        const referenceNow = Number(nowMs || Date.now());

        rawSceneState = normalizedRaw;

        if (normalizedRaw.postRainClearingEligible === false) {
            lastRainTimestampMs = 0;
        } else if (normalizedRaw.kind === "rain" || normalizedRaw.kind === "thunderstorm") {
            lastRainTimestampMs = referenceNow;
        }

        applySceneState(derivedSceneStateForRaw(normalizedRaw, referenceNow));
    }

    function refreshDerivedSceneState() {
        if (!hasFetchedOnce) {
            return;
        }

        applySceneState(derivedSceneStateForRaw(rawSceneState, Date.now()));
    }

    function normalizeRefreshDelayMs(valueMs) {
        const safeDelay = Number(valueMs);

        if (!isFinite(safeDelay) || safeDelay <= 0) {
            return root.baseRefreshIntervalMs;
        }

        return Math.max(60 * 1000, Math.round(safeDelay));
    }

    function scheduleRefreshTimer(delayMs) {
        if (!canFetch()) {
            refreshTimer.stop();
            return;
        }

        refreshTimer.interval = root.normalizeRefreshDelayMs(delayMs);
        refreshTimer.restart();
    }

    function scheduleSuccessRefresh() {
        retryAttempt = -1;
        scheduleRefreshTimer(root.baseRefreshIntervalMs);
    }

    function scheduleRetryRefresh() {
        if (retryAttempt < 0) {
            retryAttempt = 0;
        } else if (retryAttempt < (root.retryIntervalsMs.length - 1)) {
            retryAttempt += 1;
        }

        const selectedAttempt = Math.min(retryAttempt, root.retryIntervalsMs.length - 1);
        const retryDelayMs = root.retryIntervalsMs[selectedAttempt];

        scheduleRefreshTimer(retryDelayMs);
    }

    function stepTransition(deltaMs) {
        if (!visualTransitionActive) {
            return;
        }

        const duration = Math.max(320, sceneTransitionDurationMs);
        const progressStep = Math.max(0.02, Number(deltaMs || transitionTicker.interval) / duration);

        visualTransitionProgress = Math.min(1, visualTransitionProgress + progressStep);
        displaySceneState = WeatherScene.blendSceneStates(
            transitionFromSceneState,
            transitionToSceneState,
            visualTransitionProgress
        );

        if (visualTransitionProgress >= 1) {
            visualTransitionProgress = 1;
            visualTransitionActive = false;
            displaySceneState = transitionToSceneState;
            transitionFromSceneState = transitionToSceneState;
            transitionTicker.stop();
        }
    }

    function refresh() {
        if (!canFetch()) {
            fetchStatus = "inactive";
            errorText = "";

            if (!hasFetchedOnce) {
                rawSceneState = WeatherScene.defaultSceneState();
                applySceneState({
                    "status": "inactive",
                    "available": false
                });
                maxFeelsLikeTemperatureCelsius = NaN;
                lastRainTimestampMs = 0;
            }

            return;
        }

        const request = new XMLHttpRequest();
        const requestUrl = buildRequestUrl();

        fetchStatus = hasFetchedOnce ? "refreshing" : "loading";

        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            if (request.status >= 200 && request.status < 300) {
                try {
                    const responseData = JSON.parse(request.responseText);

                    root.applyRawSceneState(WeatherScene.sceneStateFromApiResponse(responseData), Date.now());
                    root.applyDailyMetrics(responseData);
                    root.fetchStatus = "ready";
                    root.errorText = "";
                    root.hasFetchedOnce = true;
                    root.scheduleSuccessRefresh();
                    return;
                } catch (error) {
                    root.handleFailure(String(error || "Parse error"));
                    return;
                }
            }

            root.handleFailure("HTTP " + request.status);
        };

        request.onerror = function() {
            root.handleFailure("Network error");
        };

        request.open("GET", requestUrl);
        request.send();
    }

    function handleFailure(message) {
        errorText = message;

        if (hasFetchedOnce) {
            fetchStatus = "stale";
        } else {
            fetchStatus = "error";
            maxFeelsLikeTemperatureCelsius = NaN;
            rawSceneState = WeatherScene.defaultSceneState();
            lastRainTimestampMs = 0;
            applySceneState({
                "status": "error",
                "available": false,
                "conditionLabel": "Unavailable"
            });
        }

        scheduleRetryRefresh();
    }

    function scheduleRefresh() {
        refreshDebounce.stop();
        refreshTimer.stop();
        retryAttempt = -1;

        if (canFetch()) {
            refreshDebounce.restart();
            return;
        }

        refresh();
    }

    onLatitudeChanged: scheduleRefresh()
    onLongitudeChanged: scheduleRefresh()
    onTimeZoneIdChanged: scheduleRefresh()
    onWeatherEnabledChanged: scheduleRefresh()
    onRefreshIntervalMsChanged: scheduleRefresh()

    Component.onCompleted: scheduleRefresh()

    Timer {
        id: refreshDebounce

        interval: 80
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: transitionTicker

        interval: 50
        repeat: true
        running: root.visualTransitionActive
        onTriggered: root.stepTransition(interval)
    }

    Timer {
        id: refreshTimer

        interval: root.baseRefreshIntervalMs
        repeat: false
        running: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.hasFetchedOnce
            && root.rawSceneState.available === true
            && root.lastRainTimestampMs > 0
            && root.rawSceneState.kind !== "rain"
            && root.rawSceneState.kind !== "thunderstorm"

        onTriggered: {
            if (root.currentClearingStrength(Date.now()) <= 0.02) {
                root.lastRainTimestampMs = 0;
            }

            root.refreshDerivedSceneState();
        }
    }
}
