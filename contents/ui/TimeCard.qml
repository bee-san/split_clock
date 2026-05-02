import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.clock

import "SolarPalette.js" as SolarPalette
import "WeatherScene.js" as WeatherScene

Item {
    id: root

    property string timeZoneId: "Local"
    property var entry: null
    property int visualRefreshCounter: 0
    property Component clockComponentOverride: null
    property Component weatherComponentOverride: null
    property var weatherStateOverride: null
    property bool cinematicWeather: true
    property bool reducedMotion: false
    property real weatherIntensity: 1
    property int weatherRefreshIntervalMinutes: 10

    function safeColor(colorValue, fallbackColor) {
        if (colorValue && colorValue.r !== undefined) {
            return colorValue;
        }

        return fallbackColor;
    }

    function blendColors(baseColor, tintColor, amount) {
        const mix = Math.max(0, Math.min(1, amount));
        const safeBaseColor = safeColor(baseColor, Qt.rgba(0.12, 0.14, 0.18, 1));
        const safeTintColor = safeColor(tintColor, safeBaseColor);

        return Qt.rgba(
            (safeBaseColor.r * (1 - mix)) + (safeTintColor.r * mix),
            (safeBaseColor.g * (1 - mix)) + (safeTintColor.g * mix),
            (safeBaseColor.b * (1 - mix)) + (safeTintColor.b * mix),
            (safeBaseColor.a * (1 - mix)) + (safeTintColor.a * mix)
        );
    }

    function withAlpha(colorValue, alphaValue) {
        const safeSourceColor = safeColor(colorValue, Qt.rgba(1, 1, 1, 1));
        return Qt.rgba(safeSourceColor.r, safeSourceColor.g, safeSourceColor.b, alphaValue);
    }

    function hashString(text) {
        let hash = 2166136261;
        const source = String(text || "");

        for (let index = 0; index < source.length; index += 1) {
            hash ^= source.charCodeAt(index);
            hash += (hash << 1) + (hash << 4) + (hash << 7) + (hash << 8) + (hash << 24);
        }

        return Math.abs(hash >>> 0);
    }

    function sampleUnit(index, salt) {
        const raw = Math.sin((zoneSeed + (index * 92821) + (salt * 68917)) * 0.000013) * 43758.5453123;
        return raw - Math.floor(raw);
    }

    function bodyTrackProgress(body) {
        const safeBody = body || {};
        const bodyX = safeBody.x !== undefined ? safeBody.x : 0.5;
        return Math.max(0, Math.min(1, (bodyX - 0.08) / 0.84));
    }

    function bodyTrackY(body) {
        const safeBody = body || {};
        const bodyY = safeBody.y !== undefined ? safeBody.y : 0.82;
        return Math.max(0.14, Math.min(0.82, bodyY));
    }

    function bodyDiameter(body) {
        const safeBody = body || {};
        const sizeScale = safeBody.sizeScale !== undefined ? safeBody.sizeScale : phasePalette.orbScale;
        return Math.max(20, Math.min(orbLaneWidth * 0.8, cardScale * (sizeScale + 0.14)));
    }

    function bodyX(body, diameter) {
        const rawX = (orbLane.width * 0.16) + ((orbLane.width * 0.58) * bodyTrackProgress(body)) - (diameter / 2);
        return Math.max(0, Math.min(orbLane.width - diameter, rawX));
    }

    function bodyY(body, diameter) {
        const rawY = (orbLane.height * bodyTrackY(body)) - (diameter / 2);
        return Math.max(0, Math.min(orbLane.height - diameter, rawY));
    }

    function clampRange(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    function copyBody(body) {
        const safeBody = body || {};

        return {
            "visible": safeBody.visible === true,
            "x": safeBody.x !== undefined ? safeBody.x : 0.5,
            "y": safeBody.y !== undefined ? safeBody.y : 0.82,
            "sizeScale": safeBody.sizeScale !== undefined ? safeBody.sizeScale : 0,
            "altitude": safeBody.altitude !== undefined ? safeBody.altitude : -90,
            "azimuth": safeBody.azimuth !== undefined ? safeBody.azimuth : 180,
            "illuminationFraction": safeBody.illuminationFraction !== undefined ? safeBody.illuminationFraction : 0,
            "terminatorAngle": safeBody.terminatorAngle !== undefined ? safeBody.terminatorAngle : 0,
            "isWaxing": safeBody.isWaxing !== false,
            "isSimplified": safeBody.isSimplified === true
        };
    }

    function maxCenterSeparation(sunDiameter, moonDiameter) {
        const totalRadius = (sunDiameter + moonDiameter) / 2;
        const maxHorizontalSeparation = Math.max(0, orbLane.width - totalRadius);
        const maxVerticalSeparation = Math.max(0, orbLane.height - totalRadius);

        return Math.sqrt((maxHorizontalSeparation * maxHorizontalSeparation) + (maxVerticalSeparation * maxVerticalSeparation));
    }

    function fitDualBodyScale(sunDiameter, moonDiameter, gapPadding) {
        if (maxCenterSeparation(sunDiameter, moonDiameter) >= ((sunDiameter + moonDiameter) / 2) + gapPadding) {
            return 1;
        }

        let minimumScale = 0.35;
        let maximumScale = 1;

        for (let iteration = 0; iteration < 14; iteration += 1) {
            const candidateScale = (minimumScale + maximumScale) / 2;
            const scaledSunDiameter = sunDiameter * candidateScale;
            const scaledMoonDiameter = moonDiameter * candidateScale;
            const candidateGap = ((scaledSunDiameter + scaledMoonDiameter) / 2) + gapPadding;

            if (maxCenterSeparation(scaledSunDiameter, scaledMoonDiameter) >= candidateGap) {
                minimumScale = candidateScale;
            } else {
                maximumScale = candidateScale;
            }
        }

        return minimumScale;
    }

    function layoutBodies(sun, moon, sunBaseDiameter, moonBaseDiameter, overlapAllowed) {
        let sunDiameter = sunBaseDiameter;
        let moonDiameter = moonBaseDiameter;
        const gapPadding = Math.max(3, Math.round(cardScale * 0.025));

        if (sun && moon && sun.visible && moon.visible && !overlapAllowed && orbLane.width > 0 && orbLane.height > 0) {
            const coexistenceScale = fitDualBodyScale(sunBaseDiameter, moonBaseDiameter, gapPadding);

            sunDiameter = sunBaseDiameter * coexistenceScale;
            moonDiameter = moonBaseDiameter * coexistenceScale;
        }

        const layout = {
            "sunDiameter": sunDiameter,
            "moonDiameter": moonDiameter,
            "sunX": bodyX(sun, sunDiameter),
            "sunY": bodyY(sun, sunDiameter),
            "moonX": bodyX(moon, moonDiameter),
            "moonY": bodyY(moon, moonDiameter)
        };

        if (!sun || !moon || !sun.visible || !moon.visible || overlapAllowed || orbLane.width <= 0 || orbLane.height <= 0) {
            return layout;
        }

        const sunHalfSize = sunDiameter / 2;
        const moonHalfSize = moonDiameter / 2;
        const minimumGap = Math.min(
            maxCenterSeparation(sunDiameter, moonDiameter) - 0.25,
            ((sunDiameter + moonDiameter) / 2) + gapPadding
        );
        const minSunCenterX = sunHalfSize;
        const maxSunCenterX = Math.max(minSunCenterX, orbLane.width - sunHalfSize);
        const minSunCenterY = sunHalfSize;
        const maxSunCenterY = Math.max(minSunCenterY, orbLane.height - sunHalfSize);
        const minMoonCenterX = moonHalfSize;
        const maxMoonCenterX = Math.max(minMoonCenterX, orbLane.width - moonHalfSize);
        const minMoonCenterY = moonHalfSize;
        const maxMoonCenterY = Math.max(minMoonCenterY, orbLane.height - moonHalfSize);

        let sunCenterX = layout.sunX + sunHalfSize;
        let sunCenterY = layout.sunY + sunHalfSize;
        let moonCenterX = layout.moonX + moonHalfSize;
        let moonCenterY = layout.moonY + moonHalfSize;
        let dx = moonCenterX - sunCenterX;
        let dy = moonCenterY - sunCenterY;
        let distance = Math.sqrt((dx * dx) + (dy * dy));

        if (minimumGap <= 0 || distance >= minimumGap) {
            return layout;
        }

        if (distance < 0.001) {
            dx = bodyTrackProgress(moon) - bodyTrackProgress(sun);
            dy = bodyTrackY(moon) - bodyTrackY(sun);

            if (Math.abs(dx) < 0.001 && Math.abs(dy) < 0.001) {
                dx = 0.35;
                dy = moon.altitude < sun.altitude ? 1 : -1;
            }

            distance = Math.max(0.001, Math.sqrt((dx * dx) + (dy * dy)));
        }

        const directionX = dx / distance;
        const directionY = dy / distance;
        const halfGap = minimumGap / 2;
        const midpointX = (sunCenterX + moonCenterX) / 2;
        const midpointY = (sunCenterY + moonCenterY) / 2;

        sunCenterX = clampRange(midpointX - (directionX * halfGap), minSunCenterX, maxSunCenterX);
        sunCenterY = clampRange(midpointY - (directionY * halfGap), minSunCenterY, maxSunCenterY);
        moonCenterX = clampRange(midpointX + (directionX * halfGap), minMoonCenterX, maxMoonCenterX);
        moonCenterY = clampRange(midpointY + (directionY * halfGap), minMoonCenterY, maxMoonCenterY);

        dx = moonCenterX - sunCenterX;
        dy = moonCenterY - sunCenterY;
        distance = Math.sqrt((dx * dx) + (dy * dy));

        if (distance < minimumGap - 0.25) {
            const horizontalDirection = directionX < 0 ? -1 : 1;
            const verticalDirection = directionY < 0 ? -1 : 1;

            sunCenterX = horizontalDirection < 0 ? maxSunCenterX : minSunCenterX;
            moonCenterX = horizontalDirection < 0 ? minMoonCenterX : maxMoonCenterX;
            sunCenterY = verticalDirection < 0 ? maxSunCenterY : minSunCenterY;
            moonCenterY = verticalDirection < 0 ? minMoonCenterY : maxMoonCenterY;
        }

        layout.sunX = clampRange(sunCenterX - sunHalfSize, 0, Math.max(0, orbLane.width - sunDiameter));
        layout.sunY = clampRange(sunCenterY - sunHalfSize, 0, Math.max(0, orbLane.height - sunDiameter));
        layout.moonX = clampRange(moonCenterX - moonHalfSize, 0, Math.max(0, orbLane.width - moonDiameter));
        layout.moonY = clampRange(moonCenterY - moonHalfSize, 0, Math.max(0, orbLane.height - moonDiameter));

        return layout;
    }

    function formatTimeValue(dateTime) {
        if (dateTime && dateTime.year !== undefined && dateTime.month !== undefined && dateTime.day !== undefined) {
            const hour = String(Number(dateTime.hour || 0)).padStart(2, "0");
            const minute = String(Number(dateTime.minute || 0)).padStart(2, "0");
            return hour + ":" + minute;
        }

        return Qt.formatDateTime(dateTime, "HH:mm");
    }

    readonly property bool isLocalTimeZone: timeZoneId === "Local"
    readonly property QtObject activeClock: clockLoader.item
    readonly property QtObject activeWeather: weatherLoader.item
    readonly property var resolvedEntry: entry || ({
        "label": timeZoneId,
        "subtitle": timeZoneId,
        "city": timeZoneId,
        "countryDisplayName": "",
        "countryName": "",
        "latitude": null,
        "longitude": null
    })
    readonly property bool hasWeatherCoordinates: WeatherScene.eligibleForWeather(resolvedEntry.latitude, resolvedEntry.longitude, timeZoneId)

    readonly property color themeBackgroundColor: root.safeColor(Kirigami.Theme.backgroundColor, Qt.rgba(0.13, 0.14, 0.17, 1))
    readonly property color themeAltBackgroundColor: root.safeColor(Kirigami.Theme.alternateBackgroundColor, Qt.rgba(0.18, 0.19, 0.24, 1))
    readonly property color themeTextColor: root.safeColor(Kirigami.Theme.textColor, Qt.rgba(1, 1, 1, 1))
    readonly property color themeHighlightColor: root.safeColor(Kirigami.Theme.highlightColor, Qt.rgba(0.35, 0.55, 0.95, 1))

    readonly property var sampledDateTime: {
        const refreshCounter = visualRefreshCounter;
        void refreshCounter;
        const sourceDateTime = activeClock ? activeClock.dateTime : new Date();

        if (sourceDateTime && sourceDateTime.year !== undefined && sourceDateTime.month !== undefined && sourceDateTime.day !== undefined) {
            return {
                "year": Number(sourceDateTime.year),
                "month": Number(sourceDateTime.month),
                "day": Number(sourceDateTime.day),
                "hour": Number(sourceDateTime.hour || 0),
                "minute": Number(sourceDateTime.minute || 0),
                "second": Number(sourceDateTime.second || 0)
            };
        }

        return sourceDateTime;
    }

    readonly property string sampledOffsetText: {
        const refreshCounter = visualRefreshCounter;
        void refreshCounter;
        return activeClock ? activeClock.timeZoneOffset : "";
    }

    readonly property var phasePalette: SolarPalette.paletteFor(sampledDateTime, resolvedEntry.latitude, resolvedEntry.longitude, sampledOffsetText)
    readonly property var weatherScene: {
        if (weatherStateOverride !== null) {
            return WeatherScene.normalizeSceneState(weatherStateOverride);
        }

        if (activeWeather && activeWeather.displaySceneState !== undefined) {
            return WeatherScene.normalizeSceneState(activeWeather.displaySceneState);
        }

        if (activeWeather && activeWeather.sceneState !== undefined) {
            return WeatherScene.normalizeSceneState(activeWeather.sceneState);
        }

        return WeatherScene.defaultSceneState();
    }
    readonly property var weatherVisualFromScene: {
        if (weatherStateOverride !== null) {
            return weatherScene;
        }

        if (activeWeather && activeWeather.transitionFromSceneState !== undefined) {
            return WeatherScene.normalizeSceneState(activeWeather.transitionFromSceneState);
        }

        return weatherScene;
    }
    readonly property var weatherVisualToScene: {
        if (weatherStateOverride !== null) {
            return weatherScene;
        }

        if (activeWeather && activeWeather.transitionToSceneState !== undefined) {
            return WeatherScene.normalizeSceneState(activeWeather.transitionToSceneState);
        }

        if (activeWeather && activeWeather.sceneState !== undefined) {
            return WeatherScene.normalizeSceneState(activeWeather.sceneState);
        }

        return weatherScene;
    }
    readonly property real weatherVisualTransitionProgress: {
        if (weatherStateOverride !== null) {
            return 1;
        }

        return activeWeather && activeWeather.visualTransitionProgress !== undefined
            ? Number(activeWeather.visualTransitionProgress)
            : 1;
    }
    readonly property bool weatherVisualTransitionActive: (
        weatherStateOverride === null
        && activeWeather
        && activeWeather.visualTransitionActive === true
        && weatherVisualTransitionProgress < 1
    )
    readonly property string weatherFetchStatus: activeWeather && activeWeather.fetchStatus !== undefined ? activeWeather.fetchStatus : weatherScene.status
    readonly property bool isMidnightPhase: phasePalette.phase === "midnight"
    readonly property bool isNightPhase: phasePalette.phase === "night" || isMidnightPhase
    readonly property bool isTwilightPhase: phasePalette.phase === "dawn"
        || phasePalette.phase === "sunrise"
        || phasePalette.phase === "sunset"
        || phasePalette.phase === "dusk"

    readonly property real accentBlendStrength: isMidnightPhase ? 0.46 : (isNightPhase ? 0.42 : 0.34)
    readonly property real skyTopBlendStrength: isMidnightPhase ? 0.84 : (isNightPhase ? 0.76 : 0.62)
    readonly property real skyMidBlendStrength: isMidnightPhase ? 0.74 : (isNightPhase ? 0.66 : 0.48)
    readonly property real skyBottomBlendStrength: isMidnightPhase ? 0.88 : (isNightPhase ? 0.82 : 0.72)
    readonly property real primaryTextBlendStrength: phasePalette.textBoost !== undefined ? phasePalette.textBoost : (isMidnightPhase ? 0.96 : (isNightPhase ? 0.9 : 0.28))
    readonly property real secondaryTextBlendStrength: Math.max(0.14, primaryTextBlendStrength * 0.82)
    readonly property string weatherVisualKind: {
        const signalKind = String(weatherScene.outsideHoursSignalKind || "");

        if (signalKind === "rain" || signalKind === "snow" || signalKind === "thunderstorm") {
            return signalKind;
        }

        return weatherScene.kind;
    }
    readonly property real weatherRainStrength: weatherVisualKind === "rain"
        ? Math.max(0.34, root.clampRange((weatherScene.rainDensity * 0.76) + (weatherScene.cloudOpacity * 0.24), 0, 1))
        : (weatherVisualKind === "thunderstorm"
            ? root.clampRange(0.84 + (weatherScene.storminess * 0.16), 0, 1)
            : 0)

    readonly property color weatherToneColor: weatherVisualKind === "snow"
        ? Qt.rgba(0.82, 0.88, 0.96, 1)
        : (weatherVisualKind === "rain"
            ? Qt.rgba(0.42, 0.47, 0.54, 1)
            : (weatherVisualKind === "thunderstorm"
                ? Qt.rgba(0.34, 0.39, 0.46, 1)
                : (weatherVisualKind === "fog"
                    ? Qt.rgba(0.72, 0.78, 0.84, 1)
                    : Qt.rgba(0.72, 0.78, 0.86, 1))))
    readonly property real weatherToneStrength: weatherVisualKind === "clear"
        ? weatherScene.cloudOpacity * 0.08
        : (weatherVisualKind === "snow"
            ? 0.3
            : (weatherVisualKind === "rain"
                ? 0.34 + (weatherRainStrength * 0.22)
                : (weatherVisualKind === "fog"
                    ? 0.4
                    : (weatherVisualKind === "thunderstorm"
                        ? 0.28 + (weatherScene.storminess * 0.18)
                        : 0.1 + (weatherScene.cloudOpacity * 0.08)))))
    readonly property real weatherDimStrength: root.clampRange(
        (weatherScene.skyDimming !== undefined ? weatherScene.skyDimming : 0) + (weatherRainStrength * 0.26),
        0,
        0.92
    )
    readonly property real weatherContrastStrength: root.clampRange(
        (weatherScene.contrastSoftening !== undefined ? weatherScene.contrastSoftening : 0) + (weatherRainStrength * 0.08),
        0,
        0.9
    )
    readonly property real weatherCoolStrength: weatherScene.coolTint !== undefined ? weatherScene.coolTint : 0
    readonly property real weatherHumidityHaze: weatherScene.humidityHaze !== undefined ? weatherScene.humidityHaze : 0
    readonly property real weatherHumidityBloom: weatherScene.humidityBloom !== undefined ? weatherScene.humidityBloom : 0
    readonly property real weatherClearingStrength: weatherScene.clearingStrength !== undefined ? weatherScene.clearingStrength : 0
    readonly property real weatherStarVisibilityFactor: weatherScene.starVisibilityFactor !== undefined ? weatherScene.starVisibilityFactor : 1
    readonly property real weatherSunGlowFactor: weatherScene.sunGlowFactor !== undefined ? weatherScene.sunGlowFactor : 1
    readonly property real weatherMoonGlowFactor: weatherScene.moonGlowFactor !== undefined ? weatherScene.moonGlowFactor : 1
    readonly property real weatherOrbOpacity: root.clampRange(
        1 - (weatherScene.cloudOpacity * 0.34) - (weatherScene.fogOpacity * 0.28) - (weatherHumidityHaze * 0.14) - (weatherRainStrength * 0.22),
        0.12,
        1
    )
    readonly property real weatherSunBodyOpacity: root.clampRange(
        weatherOrbOpacity
            * (weatherVisualKind === "rain"
                ? 0
                : (weatherVisualKind === "fog"
                    ? 0
                    : (weatherVisualKind === "snow"
                        ? 0.58
                        : (weatherVisualKind === "thunderstorm"
                            ? 0
                            : 1)))),
        0,
        1
    )
    readonly property real weatherMoonBodyOpacity: root.clampRange(
        weatherOrbOpacity
            * (weatherVisualKind === "rain"
                ? 0.72
                : (weatherVisualKind === "fog"
                    ? 0
                    : (weatherVisualKind === "snow"
                        ? 0.64
                        : (weatherVisualKind === "thunderstorm"
                            ? 0.58
                            : 1)))),
        0,
        1
    )
    readonly property real weatherHorizonFade: weatherScene.horizonFade !== undefined ? weatherScene.horizonFade : 0
    readonly property real weatherIntensityFactor: root.clampRange(weatherIntensity, 0.4, 1.4)
    readonly property real weatherAtmosphereStrength: root.clampRange(
        (
            (weatherScene.cloudOpacity * 0.3)
            + (weatherScene.fogOpacity * 0.46)
            + (weatherContrastStrength * 0.18)
            + (weatherHumidityHaze * 0.24)
            + (weatherHumidityBloom * 0.1)
            + (weatherRainStrength * 0.18)
        ) * weatherIntensityFactor,
        0,
        0.96
    )
    readonly property real orbSurfaceFlattening: root.clampRange(
        (
            (weatherScene.cloudOpacity * 0.26)
            + (weatherScene.fogOpacity * 0.42)
            + (weatherScene.celestialVeilOpacity * 0.28)
            + (weatherHumidityHaze * 0.12)
            + (weatherRainStrength * 0.16)
        ) * weatherIntensityFactor,
        0,
        0.86
    )
    readonly property real orbRimSoftening: root.clampRange(
        (
            (weatherScene.orbOcclusionOpacity * 0.42)
            + (weatherScene.fogOpacity * 0.28)
            + (weatherScene.horizonFade * 0.12)
            + (weatherHumidityBloom * 0.12)
            + (weatherClearingStrength * 0.06)
            + (weatherRainStrength * 0.2)
        ) * weatherIntensityFactor,
        0,
        0.9
    )
    readonly property color weatherShadowColor: weatherVisualKind === "thunderstorm"
        ? Qt.rgba(0.14, 0.16, 0.2, 1)
        : (weatherVisualKind === "rain"
            ? Qt.rgba(0.23, 0.26, 0.31, 1)
            : themeBackgroundColor)
    readonly property color orbAtmosphereTintColor: root.blendColors(
        root.blendColors(root.skyMidColor, root.weatherCloudColor, 0.34 + (weatherDimStrength * 0.18)),
        root.weatherFogColor,
        (weatherHumidityHaze * 0.18) + (weatherRainStrength * 0.12)
    )
    readonly property real twilightWarmth: phasePalette.twilightWarmth !== undefined ? phasePalette.twilightWarmth : 0
    readonly property real twilightCoolness: phasePalette.twilightCoolness !== undefined ? phasePalette.twilightCoolness : 0
    readonly property real twilightBandOpacity: phasePalette.twilightBandOpacity !== undefined ? phasePalette.twilightBandOpacity : 0
    readonly property real twilightHorizonBoost: phasePalette.twilightHorizonBoost !== undefined ? phasePalette.twilightHorizonBoost : 0
    readonly property real seasonalSummerStrength: phasePalette.summerStrength !== undefined ? phasePalette.summerStrength : 0

    readonly property color baseAccentColor: root.blendColors(themeHighlightColor, phasePalette.accent, accentBlendStrength)
    readonly property color baseSkyTopColor: root.blendColors(themeBackgroundColor, phasePalette.skyTop, skyTopBlendStrength)
    readonly property color baseSkyMidColor: root.blendColors(themeAltBackgroundColor, phasePalette.skyMid || phasePalette.accent, skyMidBlendStrength)
    readonly property color baseSkyBottomColor: root.blendColors(themeAltBackgroundColor, phasePalette.skyBottom, skyBottomBlendStrength)
    readonly property color baseHorizonGlowColor: root.blendColors(root.safeColor(phasePalette.horizonGlow, phasePalette.horizon), phasePalette.glow, 0.18)
    readonly property color basePrimaryTextColor: root.blendColors(themeTextColor, Qt.rgba(1, 1, 1, 1), primaryTextBlendStrength)
    readonly property color baseSecondaryTextColor: root.blendColors(themeTextColor, Qt.rgba(1, 1, 1, 1), secondaryTextBlendStrength * 0.78)

    readonly property color accentColor: root.blendColors(baseAccentColor, weatherToneColor, weatherToneStrength * 0.42)
    readonly property color skyTopColor: root.blendColors(
        root.blendColors(baseSkyTopColor, weatherToneColor, weatherToneStrength + (weatherCoolStrength * 0.06)),
        weatherShadowColor,
        weatherDimStrength + (weatherRainStrength * 0.12)
    )
    readonly property color skyMidColor: root.blendColors(
        root.blendColors(baseSkyMidColor, weatherToneColor, weatherToneStrength + (weatherCoolStrength * 0.1)),
        weatherShadowColor,
        (weatherDimStrength * 0.82) + (weatherRainStrength * 0.1)
    )
    readonly property color skyBottomColor: root.blendColors(
        root.blendColors(baseSkyBottomColor, weatherToneColor, (weatherToneStrength * 0.76) + (weatherCoolStrength * 0.18)),
        root.blendColors(weatherShadowColor, themeAltBackgroundColor, 0.38),
        (weatherDimStrength * 0.66) + (weatherRainStrength * 0.16)
    )
    readonly property color horizonGlowColor: root.blendColors(
        root.blendColors(baseHorizonGlowColor, weatherToneColor, weatherToneStrength * (weatherVisualKind === "rain" ? 0.42 : 0.16)),
        skyMidColor,
        (weatherHorizonFade * 0.4) + (weatherHumidityHaze * 0.08) + (weatherRainStrength * 0.72)
    )
    readonly property color railGlowColor: root.withAlpha(
        root.blendColors(accentColor, phasePalette.glow, 0.28 + (weatherContrastStrength * 0.06)),
        (isNightPhase ? 0.28 : 0.18) * (1 - (weatherContrastStrength * 0.18))
    )
    readonly property color sunHaloColor: root.blendColors(phasePalette.orbHalo, accentColor, 0.14)
    readonly property color sunCoreColor: root.blendColors(
        root.blendColors(phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.08),
        root.orbAtmosphereTintColor,
        weatherRainStrength * 0.76
    )
    readonly property color sunRimColor: root.blendColors(
        root.blendColors(phasePalette.orbRim || phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.18),
        root.orbAtmosphereTintColor,
        weatherRainStrength * 0.82
    )
    readonly property color moonHaloColor: root.blendColors(phasePalette.orbHalo, root.primaryTextColor, isNightPhase ? 0.1 : 0.16)
    readonly property color moonCoreColor: root.blendColors(phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.18)
    readonly property color moonRimColor: root.blendColors(phasePalette.orbRim || phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.24)
    readonly property color moonShadowColor: root.withAlpha(root.blendColors(root.skyTopColor, root.themeBackgroundColor, 0.34), phasePalette.usesSimplifiedCelestial ? 0.98 : 0.94)
    readonly property color starColor: root.blendColors(root.primaryTextColor, moonCoreColor, 0.18)
    readonly property color primaryTextColor: root.blendColors(basePrimaryTextColor, Qt.rgba(1, 1, 1, 1), weatherContrastStrength * 0.08)
    readonly property color secondaryTextColor: root.blendColors(baseSecondaryTextColor, Qt.rgba(1, 1, 1, 1), weatherContrastStrength * 0.04)
    readonly property color cardOutlineColor: root.withAlpha(root.blendColors(themeTextColor, accentColor, 0.22), isNightPhase ? 0.34 : 0.26)
    readonly property color titleShadowColor: root.withAlpha(root.blendColors(themeBackgroundColor, skyTopColor, 0.9), isNightPhase ? 0.14 : 0.1)
    readonly property color timeShadowColor: root.withAlpha(root.blendColors(themeBackgroundColor, skyMidColor, 0.92), isNightPhase ? 0.18 : 0.12)
    readonly property color topVignetteColor: root.withAlpha(root.blendColors(themeBackgroundColor, skyTopColor, 0.84), phasePalette.vignetteOpacity || 0.16)
    readonly property color edgeHighlightColor: root.withAlpha(root.blendColors(Qt.rgba(1, 1, 1, 1), sunRimColor, 0.14), isNightPhase ? 0.18 : 0.12)
    readonly property color weatherCloudColor: root.blendColors(
        root.skyMidColor,
        weatherRainStrength > 0
            ? Qt.rgba(0.62, 0.67, 0.75, 1)
            : Qt.rgba(1, 1, 1, 1),
        (weatherVisualKind === "snow" ? 0.32 : (weatherRainStrength > 0 ? 0.22 : 0.18)) + (weatherHumidityHaze * 0.08)
    )
    readonly property color weatherCloudHighlightColor: root.blendColors(
        root.weatherCloudColor,
        Qt.rgba(1, 1, 1, 1),
        (weatherVisualKind === "snow" ? 0.26 : (weatherRainStrength > 0 ? 0.08 : 0.34)) + (weatherHumidityBloom * 0.08)
    )
    readonly property color weatherCloudShadowColor: root.blendColors(
        root.skyMidColor,
        root.themeBackgroundColor,
        0.42 + (weatherDimStrength * 0.08) + (weatherRainStrength * 0.22)
    )
    readonly property color weatherPrecipitationColor: root.blendColors(
        root.primaryTextColor,
        weatherRainStrength > 0 ? Qt.rgba(0.74, 0.84, 0.96, 1) : Qt.rgba(0.82, 0.92, 1, 1),
        weatherRainStrength > 0 ? 0.62 : 0.34
    )
    readonly property color weatherSnowColor: root.blendColors(
        Qt.rgba(1, 1, 1, 1),
        root.weatherCloudHighlightColor,
        0.26
    )
    readonly property color weatherFogColor: root.blendColors(
        root.skyMidColor,
        Qt.rgba(0.96, 0.98, 1, 1),
        0.82 + (weatherHumidityHaze * 0.12)
    )
    readonly property color twilightWarmColor: root.blendColors(
        root.blendColors(phasePalette.horizonGlow, Qt.rgba(1, 0.82, 0.68, 1), Math.min(0.42, twilightWarmth * 0.34)),
        skyMidColor,
        weatherRainStrength > 0 ? Math.min(0.86, 0.56 + (weatherRainStrength * 0.24)) : 0
    )
    readonly property color twilightCoolColor: root.blendColors(phasePalette.skyTop, phasePalette.accent, Math.min(0.56, twilightCoolness * 0.42))

    readonly property string cityLabel: resolvedEntry.city || resolvedEntry.label || timeZoneId
    readonly property string timeText: root.formatTimeValue(sampledDateTime)
    readonly property real maxFeelsLikeTemperatureCelsius: {
        if (weatherStateOverride !== null && weatherStateOverride.maxFeelsLikeTemperatureCelsius !== undefined) {
            return Number(weatherStateOverride.maxFeelsLikeTemperatureCelsius);
        }

        return activeWeather && activeWeather.maxFeelsLikeTemperatureCelsius !== undefined
            ? Number(activeWeather.maxFeelsLikeTemperatureCelsius)
            : NaN;
    }
    readonly property bool hasMaxFeelsLikeTemperature: isFinite(maxFeelsLikeTemperatureCelsius)
    readonly property string maxFeelsLikeTemperatureText: hasMaxFeelsLikeTemperature ? Math.round(maxFeelsLikeTemperatureCelsius) + "C" : ""
    readonly property bool hasOutsideHoursWeatherCue: {
        const signalKind = String(weatherScene.outsideHoursSignalKind || "");

        return signalKind === "rain" || signalKind === "snow" || signalKind === "thunderstorm";
    }
    readonly property string outsideHoursWeatherCueText: {
        if (!weatherScene || weatherScene.available !== true || !hasOutsideHoursWeatherCue) {
            return "";
        }

        return String(weatherScene.outsideHoursSignalLabel || "").toUpperCase() + " OUTSIDE";
    }
    readonly property string outsideHoursWeatherCueGlyph: {
        const signalKind = String(weatherScene.outsideHoursSignalKind || "");

        if (signalKind === "thunderstorm") {
            return "⚡";
        }

        if (signalKind === "snow") {
            return "❄";
        }

        if (signalKind === "rain") {
            return "☂";
        }

        return "";
    }
    readonly property color outsideHoursWeatherCueBackgroundColor: {
        const signalKind = String(weatherScene.outsideHoursSignalKind || "");

        if (signalKind === "thunderstorm") {
            return Qt.rgba(0.18, 0.2, 0.26, 0.92);
        }

        if (signalKind === "snow") {
            return Qt.rgba(0.76, 0.83, 0.92, 0.9);
        }

        if (signalKind === "rain") {
            return Qt.rgba(0.26, 0.35, 0.48, 0.9);
        }

        return Qt.rgba(0, 0, 0, 0);
    }
    readonly property color outsideHoursWeatherCueBorderColor: {
        const signalKind = String(weatherScene.outsideHoursSignalKind || "");

        if (signalKind === "thunderstorm") {
            return Qt.rgba(0.92, 0.76, 0.18, 0.68);
        }

        if (signalKind === "snow") {
            return Qt.rgba(0.94, 0.97, 1, 0.72);
        }

        if (signalKind === "rain") {
            return Qt.rgba(0.78, 0.88, 1, 0.7);
        }

        return Qt.rgba(0, 0, 0, 0);
    }
    readonly property color outsideHoursWeatherCueTextColor: {
        const signalKind = String(weatherScene.outsideHoursSignalKind || "");

        return signalKind === "snow"
            ? Qt.rgba(0.1, 0.16, 0.24, 1)
            : Qt.rgba(0.98, 0.99, 1, 1);
    }
    readonly property string weatherConditionGlyph: {
        if (weatherScene.available !== true) {
            return "";
        }

        if (weatherScene.outsideHoursSignalKind === "thunderstorm" && weatherScene.kind !== "thunderstorm") {
            return "⚡";
        }

        if (weatherScene.outsideHoursSignalKind === "snow" && weatherScene.kind !== "snow") {
            return "❄";
        }

        if (weatherScene.outsideHoursSignalKind === "rain" && weatherScene.kind !== "rain") {
            return "☂";
        }

        if (weatherScene.kind === "thunderstorm") {
            return "⚡";
        }

        if (weatherScene.kind === "snow") {
            return "❄";
        }

        if (weatherScene.kind === "rain") {
            return "☂";
        }

        if (weatherScene.kind === "fog") {
            return "≋";
        }

        if (weatherScene.kind === "cloudy") {
            return "☁";
        }

        return root.isNightPhase ? "☾" : "☀";
    }
    readonly property bool showWeatherStatusCluster: weatherFetchStatus !== "inactive"
        && (weatherScene.available === true || hasMaxFeelsLikeTemperature)
    readonly property int zoneSeed: root.hashString(timeZoneId + "|" + cityLabel)
    readonly property var sunBody: phasePalette.sunBody || ({ "visible": false, "x": 0.5, "y": 0.82, "sizeScale": 0 })
    readonly property var moonBody: phasePalette.moonBody || ({ "visible": false, "x": 0.5, "y": 0.82, "sizeScale": 0 })
    readonly property bool suppressSecondaryDayOrb: root.sunBody.visible && root.moonBody.visible
    readonly property var renderedSunBody: {
        const body = root.copyBody(root.sunBody);

        body.visible = root.sunBody.visible;

        return body;
    }
    readonly property var renderedMoonBody: {
        const body = root.copyBody(root.moonBody);

        body.visible = root.moonBody.visible && !root.sunBody.visible;

        return body;
    }
    readonly property color orbLightColor: root.renderedSunBody.visible
        ? root.blendColors(root.sunHaloColor, Qt.rgba(1, 1, 1, 1), 0.34)
        : root.blendColors(root.moonHaloColor, root.primaryTextColor, 0.18)
    readonly property color orbLightAccentColor: root.renderedSunBody.visible
        ? root.blendColors(root.sunCoreColor, root.twilightWarmColor, 0.2 + (root.twilightWarmth * 0.12))
        : root.blendColors(root.moonCoreColor, Qt.rgba(0.88, 0.94, 1, 1), 0.22)

    readonly property real cardScale: Math.max(1, Math.min(width, height))
    readonly property real frameRadius: 0
    readonly property int contentInset: Math.max(10, Math.round(cardScale * 0.085))
    readonly property int columnGap: Math.max(10, Math.round(cardScale * 0.05))
    readonly property int titleGap: Math.max(4, Math.round(cardScale * 0.026))
    readonly property real orbLaneWidth: Math.max(64, Math.min(width * 0.26, height * 0.72))
    readonly property real textRightInset: orbLaneWidth + columnGap
    readonly property real textColumnWidth: Math.max(72, width - (contentInset * 2) - textRightInset)
    readonly property int cityFontSize: Math.max(14, Math.round(Math.min(textColumnWidth * 0.16, height * 0.22)))
    readonly property int timeFontSize: Math.max(28, Math.round(Math.min(textColumnWidth * 0.42, height * 0.64)))
    readonly property int minTimeFontSize: Math.max(20, Math.round(timeFontSize * 0.62))
    readonly property int weatherMetricFontSize: Math.max(9, Math.round(Math.min(cardScale * 0.11, height * 0.12)))
    readonly property int weatherGlyphFontSize: Math.max(10, Math.round(weatherMetricFontSize * 0.92))
    readonly property int starCount: Math.max(0, Math.round((phasePalette.starDensity || 0) * 16 * weatherStarVisibilityFactor))
    readonly property real sunBodyBaseDiameter: root.bodyDiameter(renderedSunBody)
    readonly property real moonBodyBaseDiameter: root.bodyDiameter(renderedMoonBody)
    readonly property real timeShadowOffset: Math.max(1, Math.round(cardScale * 0.012))
    readonly property var bodyLayout: root.layoutBodies(
        root.renderedSunBody,
        root.renderedMoonBody,
        root.sunBodyBaseDiameter,
        root.moonBodyBaseDiameter,
        phasePalette.allowBodyOverlap === true
    )
    readonly property real sunBodyDiameter: bodyLayout.sunDiameter
    readonly property real moonBodyDiameter: bodyLayout.moonDiameter

    implicitWidth: Kirigami.Units.gridUnit * 11
    implicitHeight: Kirigami.Units.gridUnit * 5.7

    Timer {
        interval: 1800000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.visualRefreshCounter += 1
    }

    Loader {
        id: clockLoader

        active: true
        sourceComponent: root.clockComponentOverride || (root.isLocalTimeZone ? localClockComponent : configuredClockComponent)
    }

    Loader {
        id: weatherLoader

        active: root.weatherStateOverride === null && (root.weatherComponentOverride !== null || root.hasWeatherCoordinates)
        sourceComponent: root.weatherComponentOverride || liveWeatherSourceComponent
    }

    Component {
        id: localClockComponent

        Clock {
            trackSeconds: false
        }
    }

    Component {
        id: configuredClockComponent

        Clock {
            trackSeconds: false
            timeZone: root.timeZoneId
        }
    }

    Component {
        id: liveWeatherSourceComponent

        WeatherSource {
            latitude: Number(root.resolvedEntry.latitude)
            longitude: Number(root.resolvedEntry.longitude)
            timeZoneId: root.timeZoneId
            refreshIntervalMs: Math.max(1, root.weatherRefreshIntervalMinutes) * 60 * 1000
        }
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        radius: root.frameRadius
        antialiasing: false
        border.width: 0
        border.color: Qt.rgba(0, 0, 0, 0)
        clip: true
        layer.enabled: false
        layer.smooth: false
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.blendColors(root.skyTopColor, root.skyMidColor, root.isNightPhase ? 0.46 : 0.22)
            }
            GradientStop {
                position: 0.16
                color: root.skyTopColor
            }
            GradientStop {
                position: 0.52
                color: root.skyMidColor
            }
            GradientStop {
                position: 1
                color: root.skyBottomColor
            }
        }

        Rectangle {
            id: twilightSkyBand

            objectName: "twilightSkyBandItem"
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.46
            visible: root.isTwilightPhase && root.twilightBandOpacity > 0.02
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.twilightCoolColor, root.twilightBandOpacity * (0.46 + (root.twilightCoolness * 0.2)))
                }
                GradientStop {
                    position: 0.42
                    color: root.withAlpha(root.twilightWarmColor, root.twilightBandOpacity * (0.14 + (root.twilightWarmth * 0.08)))
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        Rectangle {
            width: frame.width * 1.12
            height: frame.height * (0.28 + (phasePalette.hazeOpacity * 0.34))
            radius: height / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -height * 0.26
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.horizonGlowColor, 0)
                }
                GradientStop {
                    position: 0.52
                    color: root.withAlpha(root.horizonGlowColor, 0.06 + (phasePalette.glowOpacity * 0.04))
                }
                GradientStop {
                    position: 1
                    color: root.withAlpha(root.horizonGlowColor, 0.2 + (phasePalette.glowOpacity * 0.14))
                }
            }
        }

        Rectangle {
            id: twilightHorizonBand

            objectName: "twilightHorizonBandItem"
            width: frame.width * 1.16
            height: frame.height * (0.18 + (root.twilightHorizonBoost * 0.16))
            radius: height / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -height * 0.18
            visible: root.isTwilightPhase && root.twilightHorizonBoost > 0.02
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.twilightWarmColor, 0)
                }
                GradientStop {
                    position: 0.44
                    color: root.withAlpha(root.twilightWarmColor, (0.08 + (root.twilightWarmth * 0.1)) * (1 - (root.weatherHorizonFade * 0.42)))
                }
                GradientStop {
                    position: 1
                    color: root.withAlpha(root.twilightWarmColor, (0.14 + (root.twilightHorizonBoost * 0.16)) * (1 - (root.weatherHorizonFade * 0.36)))
                }
            }
        }

        Repeater {
            model: root.starCount

            delegate: Item {
                required property int index

                readonly property real horizontalUnit: root.sampleUnit(index + 1, 1)
                readonly property real verticalUnit: root.sampleUnit(index + 1, 2)
                readonly property real starSize: 0.008 + (root.sampleUnit(index + 1, 3) * 0.012)
                readonly property real twinkle: 0.52 + (root.sampleUnit(index + 1, 4) * 0.38)

                width: Math.max(1, Math.round(root.cardScale * starSize))
                height: width
                x: horizontalUnit * (frame.width - width)
                y: verticalUnit * (frame.height * 0.42)
                opacity: phasePalette.starOpacity * twinkle * root.weatherStarVisibilityFactor

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 2.6
                    height: width
                    radius: width / 2
                    color: root.withAlpha(root.starColor, parent.opacity * 0.18)
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: width
                    radius: width / 2
                    color: root.withAlpha(Qt.rgba(1, 1, 1, 1), parent.opacity * 0.88)
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.3
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, 0)
                }
                GradientStop {
                    position: 0.18
                    color: root.withAlpha(root.topVignetteColor, root.topVignetteColor.a * 0.72)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        Item {
            id: orbLane

            objectName: "orbLaneItem"
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: root.contentInset
            anchors.bottomMargin: root.contentInset
            anchors.rightMargin: root.contentInset
            width: root.orbLaneWidth

            CelestialBody {
                id: sunBodyItem

                objectName: "sunBodyItem"
                bodyData: root.renderedSunBody
                moon: false
                width: root.sunBodyDiameter
                height: width
                x: root.bodyLayout.sunX
                y: root.bodyLayout.sunY
                haloColor: root.sunHaloColor
                coreColor: root.sunCoreColor
                rimColor: root.sunRimColor
                shadowColor: root.moonShadowColor
                glowOpacity: phasePalette.glowOpacity * (root.weatherSunGlowFactor + (root.weatherHumidityBloom * 0.22))
                rimOpacity: root.isNightPhase ? 0.34 : 0.26
                atmosphereTintColor: root.orbAtmosphereTintColor
                atmosphericVeilOpacity: root.weatherAtmosphereStrength * 0.34
                surfaceFlattening: root.orbSurfaceFlattening
                rimSoftening: root.orbRimSoftening
                opacity: root.weatherSunBodyOpacity
                z: 1
            }

            CelestialBody {
                id: moonBodyItem

                objectName: "moonBodyItem"
                bodyData: root.renderedMoonBody
                moon: true
                width: root.moonBodyDiameter
                height: width
                x: root.bodyLayout.moonX
                y: root.bodyLayout.moonY
                haloColor: root.moonHaloColor
                coreColor: root.moonCoreColor
                rimColor: root.moonRimColor
                shadowColor: root.moonShadowColor
                glowOpacity: (root.isNightPhase ? Math.max(phasePalette.glowOpacity, 0.12) : (phasePalette.glowOpacity * 0.72))
                    * (root.weatherMoonGlowFactor + (root.weatherHumidityBloom * 0.12))
                rimOpacity: root.isNightPhase ? 0.38 : 0.28
                atmosphereTintColor: root.orbAtmosphereTintColor
                atmosphericVeilOpacity: root.weatherAtmosphereStrength * 0.42
                surfaceFlattening: root.orbSurfaceFlattening * 0.9
                rimSoftening: root.orbRimSoftening
                opacity: root.weatherMoonBodyOpacity
                pulse: false
                z: 2
            }
        }

        WeatherOverlay {
            anchors.fill: parent
            visible: root.weatherVisualTransitionActive
            opacity: root.weatherVisualTransitionActive ? Math.max(0, 1 - root.weatherVisualTransitionProgress) : 0
            sceneState: root.weatherVisualFromScene
            zoneSeed: root.zoneSeed
            cardScale: root.cardScale
            sunRect: ({
                "visible": root.renderedSunBody.visible && root.weatherSunBodyOpacity > 0.1,
                "x": orbLane.x + sunBodyItem.x,
                "y": orbLane.y + sunBodyItem.y,
                "width": sunBodyItem.width,
                "height": sunBodyItem.height
            })
            moonRect: ({
                "visible": root.renderedMoonBody.visible && root.weatherMoonBodyOpacity > 0.1,
                "x": orbLane.x + moonBodyItem.x,
                "y": orbLane.y + moonBodyItem.y,
                "width": moonBodyItem.width,
                "height": moonBodyItem.height
            })
            cloudHighlightColor: root.weatherCloudHighlightColor
            cloudShadowColor: root.weatherCloudShadowColor
            orbLightColor: root.orbLightColor
            orbLightAccentColor: root.orbLightAccentColor
            twilightWarmColor: root.twilightWarmColor
            twilightCoolColor: root.twilightCoolColor
            twilightWarmth: root.twilightWarmth
            twilightCoolness: root.twilightCoolness
            twilightActive: root.isTwilightPhase
            cinematicWeather: root.cinematicWeather
            reducedMotion: root.reducedMotion
            weatherIntensity: root.weatherIntensityFactor
            summerStrength: root.seasonalSummerStrength
            cloudColor: root.weatherCloudColor
            precipitationColor: root.weatherPrecipitationColor
            snowColor: root.weatherSnowColor
            fogColor: root.weatherFogColor
        }

        WeatherOverlay {
            anchors.fill: parent
            opacity: root.weatherVisualTransitionActive ? Math.min(1, root.weatherVisualTransitionProgress) : 1
            sceneState: root.weatherVisualToScene
            zoneSeed: root.zoneSeed
            cardScale: root.cardScale
            sunRect: ({
                "visible": root.renderedSunBody.visible && root.weatherSunBodyOpacity > 0.1,
                "x": orbLane.x + sunBodyItem.x,
                "y": orbLane.y + sunBodyItem.y,
                "width": sunBodyItem.width,
                "height": sunBodyItem.height
            })
            moonRect: ({
                "visible": root.renderedMoonBody.visible && root.weatherMoonBodyOpacity > 0.1,
                "x": orbLane.x + moonBodyItem.x,
                "y": orbLane.y + moonBodyItem.y,
                "width": moonBodyItem.width,
                "height": moonBodyItem.height
            })
            cloudHighlightColor: root.weatherCloudHighlightColor
            cloudShadowColor: root.weatherCloudShadowColor
            orbLightColor: root.orbLightColor
            orbLightAccentColor: root.orbLightAccentColor
            twilightWarmColor: root.twilightWarmColor
            twilightCoolColor: root.twilightCoolColor
            twilightWarmth: root.twilightWarmth
            twilightCoolness: root.twilightCoolness
            twilightActive: root.isTwilightPhase
            cinematicWeather: root.cinematicWeather
            reducedMotion: root.reducedMotion
            weatherIntensity: root.weatherIntensityFactor
            summerStrength: root.seasonalSummerStrength
            cloudColor: root.weatherCloudColor
            precipitationColor: root.weatherPrecipitationColor
            snowColor: root.weatherSnowColor
            fogColor: root.weatherFogColor
        }

        Item {
            id: weatherHud

            objectName: "weatherHudItem"
            visible: root.showWeatherStatusCluster
            z: 6
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Math.max(6, Math.round(root.contentInset * 0.72))
            anchors.rightMargin: Math.max(6, Math.round(root.contentInset * 0.72))
            width: weatherHudRow.implicitWidth
            height: weatherHudRow.implicitHeight

            Row {
                id: weatherHudRow

                spacing: Math.max(3, Math.round(root.cardScale * 0.016))

                Item {
                    visible: root.weatherConditionGlyph.length > 0
                    width: weatherConditionGlyphForeground.implicitWidth
                    height: weatherConditionGlyphForeground.implicitHeight

                    Text {
                        id: weatherConditionGlyphShadow

                        anchors.fill: parent
                        anchors.leftMargin: 1
                        anchors.topMargin: 1
                        color: root.timeShadowColor
                        text: root.weatherConditionGlyph
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: root.weatherGlyphFontSize
                        renderType: Text.QtRendering
                    }

                    Text {
                        id: weatherConditionGlyphForeground

                        objectName: "weatherConditionGlyphTextItem"
                        anchors.fill: parent
                        color: root.primaryTextColor
                        text: root.weatherConditionGlyph
                        font.family: Kirigami.Theme.defaultFont.family
                        font.pixelSize: root.weatherGlyphFontSize
                        renderType: Text.QtRendering
                    }
                }

                Item {
                    visible: false
                    width: outsideHoursCueBadge.width
                    height: outsideHoursCueBadge.height

                    Rectangle {
                        id: outsideHoursCueBadge

                        width: implicitWidth
                        height: implicitHeight
                        implicitWidth: outsideHoursCueRow.implicitWidth + Math.max(8, Math.round(root.cardScale * 0.03))
                        implicitHeight: outsideHoursCueRow.implicitHeight + Math.max(4, Math.round(root.cardScale * 0.014))
                        radius: height / 2
                        color: Qt.rgba(
                            root.outsideHoursWeatherCueBackgroundColor.r,
                            root.outsideHoursWeatherCueBackgroundColor.g,
                            root.outsideHoursWeatherCueBackgroundColor.b,
                            root.outsideHoursWeatherCueBackgroundColor.a * 0.78
                        )
                        border.width: 1
                        border.color: Qt.rgba(
                            root.outsideHoursWeatherCueBorderColor.r,
                            root.outsideHoursWeatherCueBorderColor.g,
                            root.outsideHoursWeatherCueBorderColor.b,
                            root.outsideHoursWeatherCueBorderColor.a * 0.7
                        )

                        Row {
                            id: outsideHoursCueRow

                            anchors.centerIn: parent
                            spacing: Math.max(2, Math.round(root.cardScale * 0.008))

                            Text {
                                visible: false
                                color: root.outsideHoursWeatherCueTextColor
                                text: root.outsideHoursWeatherCueGlyph
                                font.family: Kirigami.Theme.defaultFont.family
                                font.bold: true
                                font.weight: Font.DemiBold
                                font.pixelSize: Math.max(9, Math.round(root.weatherMetricFontSize * 0.86))
                                renderType: Text.QtRendering
                            }

                            Text {
                                id: outsideHoursCueForeground

                                objectName: "outsideHoursWeatherCueTextItem"
                                color: root.outsideHoursWeatherCueTextColor
                                text: root.outsideHoursWeatherCueText
                                font.family: Kirigami.Theme.defaultFont.family
                                font.bold: true
                                font.weight: Font.DemiBold
                                font.pixelSize: Math.max(8, Math.round(root.weatherMetricFontSize * 0.84))
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }

                Item {
                    visible: root.hasMaxFeelsLikeTemperature
                    width: maxFeelsLikeForeground.implicitWidth
                    height: maxFeelsLikeForeground.implicitHeight

                    Text {
                        id: maxFeelsLikeShadow

                        anchors.fill: parent
                        anchors.leftMargin: 1
                        anchors.topMargin: 1
                        color: root.timeShadowColor
                        text: root.maxFeelsLikeTemperatureText
                        font.family: Kirigami.Theme.defaultFont.family
                        font.bold: true
                        font.weight: Font.DemiBold
                        font.pixelSize: root.weatherMetricFontSize
                        renderType: Text.NativeRendering
                    }

                    Text {
                        id: maxFeelsLikeForeground

                        objectName: "maxFeelsLikeTextItem"
                        anchors.fill: parent
                        color: root.primaryTextColor
                        text: root.maxFeelsLikeTemperatureText
                        font.family: Kirigami.Theme.defaultFont.family
                        font.bold: true
                        font.weight: Font.DemiBold
                        font.pixelSize: root.weatherMetricFontSize
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Item {
            id: textColumn

            objectName: "textColumnItem"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: orbLane.left
            anchors.leftMargin: root.contentInset
            anchors.topMargin: root.contentInset
            anchors.bottomMargin: root.contentInset
            anchors.rightMargin: root.columnGap

            Item {
                id: cityBox

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(root.cityFontSize * 1.15, parent.height * 0.16)

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 1
                    anchors.topMargin: 1
                    color: root.titleShadowColor
                    text: root.cityLabel
                    font.family: Kirigami.Theme.defaultFont.family
                    font.bold: true
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                    font.pixelSize: root.cityFontSize
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 12
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    verticalAlignment: Text.AlignTop
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.fill: parent
                    color: root.primaryTextColor
                    text: root.cityLabel
                    font.family: Kirigami.Theme.defaultFont.family
                    font.bold: true
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                    font.pixelSize: root.cityFontSize
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 12
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    verticalAlignment: Text.AlignTop
                    renderType: Text.NativeRendering
                }
            }

            Item {
                id: timeBox

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: cityBox.bottom
                anchors.topMargin: root.titleGap
                anchors.bottom: parent.bottom

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: root.timeShadowOffset
                    anchors.bottomMargin: -1 + root.timeShadowOffset
                    color: root.timeShadowColor
                    text: root.timeText
                    font.family: Kirigami.Theme.defaultFont.family
                    font.bold: true
                    font.weight: Font.Bold
                    font.letterSpacing: -1.4
                    font.pixelSize: root.timeFontSize
                    fontSizeMode: Text.Fit
                    minimumPixelSize: root.minTimeFontSize
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignBottom
                    wrapMode: Text.NoWrap
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.fill: parent
                    color: root.primaryTextColor
                    text: root.timeText
                    font.family: Kirigami.Theme.defaultFont.family
                    font.bold: true
                    font.weight: Font.Bold
                    font.letterSpacing: -1.4
                    font.pixelSize: root.timeFontSize
                    fontSizeMode: Text.Fit
                    minimumPixelSize: root.minTimeFontSize
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignBottom
                    wrapMode: Text.NoWrap
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
