import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.clock

import "SolarPalette.js" as SolarPalette

Item {
    id: root

    property string timeZoneId: "Local"
    property var entry: null
    property int visualRefreshCounter: 0
    property Component clockComponentOverride: null

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
    readonly property var resolvedEntry: entry || ({
        "label": timeZoneId,
        "subtitle": timeZoneId,
        "city": timeZoneId,
        "countryDisplayName": "",
        "countryName": "",
        "latitude": null,
        "longitude": null
    })

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
    readonly property bool isMidnightPhase: phasePalette.phase === "midnight"
    readonly property bool isNightPhase: phasePalette.phase === "night" || isMidnightPhase

    readonly property real accentBlendStrength: isMidnightPhase ? 0.46 : (isNightPhase ? 0.42 : 0.34)
    readonly property real skyTopBlendStrength: isMidnightPhase ? 0.84 : (isNightPhase ? 0.76 : 0.62)
    readonly property real skyMidBlendStrength: isMidnightPhase ? 0.74 : (isNightPhase ? 0.66 : 0.48)
    readonly property real skyBottomBlendStrength: isMidnightPhase ? 0.88 : (isNightPhase ? 0.82 : 0.72)
    readonly property real primaryTextBlendStrength: phasePalette.textBoost !== undefined ? phasePalette.textBoost : (isMidnightPhase ? 0.96 : (isNightPhase ? 0.9 : 0.28))
    readonly property real secondaryTextBlendStrength: Math.max(0.14, primaryTextBlendStrength * 0.82)

    readonly property color accentColor: root.blendColors(themeHighlightColor, phasePalette.accent, accentBlendStrength)
    readonly property color skyTopColor: root.blendColors(themeBackgroundColor, phasePalette.skyTop, skyTopBlendStrength)
    readonly property color skyMidColor: root.blendColors(themeAltBackgroundColor, phasePalette.skyMid || phasePalette.accent, skyMidBlendStrength)
    readonly property color skyBottomColor: root.blendColors(themeAltBackgroundColor, phasePalette.skyBottom, skyBottomBlendStrength)
    readonly property color horizonGlowColor: root.blendColors(root.safeColor(phasePalette.horizonGlow, phasePalette.horizon), phasePalette.glow, 0.18)
    readonly property color railGlowColor: root.withAlpha(root.blendColors(accentColor, phasePalette.glow, 0.28), isNightPhase ? 0.28 : 0.18)
    readonly property color sunHaloColor: root.blendColors(phasePalette.orbHalo, accentColor, 0.14)
    readonly property color sunCoreColor: root.blendColors(phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.08)
    readonly property color sunRimColor: root.blendColors(phasePalette.orbRim || phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.18)
    readonly property color moonHaloColor: root.blendColors(phasePalette.orbHalo, root.primaryTextColor, isNightPhase ? 0.1 : 0.16)
    readonly property color moonCoreColor: root.blendColors(phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.18)
    readonly property color moonRimColor: root.blendColors(phasePalette.orbRim || phasePalette.orbCore, Qt.rgba(1, 1, 1, 1), 0.24)
    readonly property color moonShadowColor: root.withAlpha(root.blendColors(root.skyTopColor, root.themeBackgroundColor, 0.34), phasePalette.usesSimplifiedCelestial ? 0.98 : 0.94)
    readonly property color starColor: root.blendColors(root.primaryTextColor, moonCoreColor, 0.18)
    readonly property color primaryTextColor: root.blendColors(themeTextColor, Qt.rgba(1, 1, 1, 1), primaryTextBlendStrength)
    readonly property color secondaryTextColor: root.blendColors(themeTextColor, Qt.rgba(1, 1, 1, 1), secondaryTextBlendStrength * 0.78)
    readonly property color cardOutlineColor: root.withAlpha(root.blendColors(themeTextColor, accentColor, 0.22), isNightPhase ? 0.34 : 0.26)
    readonly property color titleShadowColor: root.withAlpha(root.blendColors(themeBackgroundColor, skyTopColor, 0.9), isNightPhase ? 0.14 : 0.1)
    readonly property color timeShadowColor: root.withAlpha(root.blendColors(themeBackgroundColor, skyMidColor, 0.92), isNightPhase ? 0.18 : 0.12)
    readonly property color topVignetteColor: root.withAlpha(root.blendColors(themeBackgroundColor, skyTopColor, 0.84), phasePalette.vignetteOpacity || 0.16)
    readonly property color edgeHighlightColor: root.withAlpha(root.blendColors(Qt.rgba(1, 1, 1, 1), sunRimColor, 0.14), isNightPhase ? 0.18 : 0.12)

    readonly property string cityLabel: resolvedEntry.city || resolvedEntry.label || timeZoneId
    readonly property string timeText: root.formatTimeValue(sampledDateTime)
    readonly property int zoneSeed: root.hashString(timeZoneId + "|" + cityLabel)
    readonly property var sunBody: phasePalette.sunBody || ({ "visible": false, "x": 0.5, "y": 0.82, "sizeScale": 0 })
    readonly property var moonBody: phasePalette.moonBody || ({ "visible": false, "x": 0.5, "y": 0.82, "sizeScale": 0 })

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
    readonly property int starCount: Math.max(0, Math.round((phasePalette.starDensity || 0) * 16))
    readonly property real sunBodyBaseDiameter: root.bodyDiameter(sunBody)
    readonly property real moonBodyBaseDiameter: root.bodyDiameter(moonBody)
    readonly property real timeShadowOffset: Math.max(1, Math.round(cardScale * 0.012))
    readonly property var bodyLayout: root.layoutBodies(
        root.sunBody,
        root.moonBody,
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
                opacity: phasePalette.starOpacity * twinkle

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
                bodyData: root.sunBody
                moon: false
                width: root.sunBodyDiameter
                height: width
                x: root.bodyLayout.sunX
                y: root.bodyLayout.sunY
                haloColor: root.sunHaloColor
                coreColor: root.sunCoreColor
                rimColor: root.sunRimColor
                shadowColor: root.moonShadowColor
                glowOpacity: phasePalette.glowOpacity
                rimOpacity: root.isNightPhase ? 0.34 : 0.26
                z: 1
            }

            CelestialBody {
                id: moonBodyItem

                objectName: "moonBodyItem"
                bodyData: root.moonBody
                moon: true
                width: root.moonBodyDiameter
                height: width
                x: root.bodyLayout.moonX
                y: root.bodyLayout.moonY
                haloColor: root.moonHaloColor
                coreColor: root.moonCoreColor
                rimColor: root.moonRimColor
                shadowColor: root.moonShadowColor
                glowOpacity: root.isNightPhase ? Math.max(phasePalette.glowOpacity, 0.12) : (phasePalette.glowOpacity * 0.72)
                rimOpacity: root.isNightPhase ? 0.38 : 0.28
                pulse: false
                z: 2
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
