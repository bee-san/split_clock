import QtQuick 2.15

Item {
    id: root

    objectName: "weatherOverlayItem"

    property var sceneState: null
    property int zoneSeed: 0
    property color cloudColor: Qt.rgba(0.78, 0.82, 0.88, 1)
    property color cloudHighlightColor: Qt.rgba(0.92, 0.94, 0.98, 1)
    property color cloudShadowColor: Qt.rgba(0.54, 0.6, 0.7, 1)
    property color orbLightColor: Qt.rgba(1, 1, 1, 1)
    property color orbLightAccentColor: Qt.rgba(1, 1, 1, 1)
    property color precipitationColor: Qt.rgba(0.72, 0.82, 0.96, 1)
    property color snowColor: Qt.rgba(1, 1, 1, 1)
    property color fogColor: Qt.rgba(0.92, 0.94, 0.98, 1)
    property color lightningColor: Qt.rgba(1, 1, 1, 1)
    property color twilightWarmColor: Qt.rgba(1, 0.82, 0.68, 1)
    property color twilightCoolColor: Qt.rgba(0.6, 0.7, 0.9, 1)
    property real twilightWarmth: 0
    property real twilightCoolness: 0
    property bool twilightActive: false
    property bool cinematicWeather: true
    property bool reducedMotion: false
    property real weatherIntensity: 1
    property real summerStrength: 0
    property real cardScale: Math.max(width, height)
    property var sunRect: null
    property var moonRect: null

    readonly property string weatherKind: sceneState && sceneState.kind ? String(sceneState.kind) : "clear"
    readonly property string outsideHoursSignalKind: sceneState && sceneState.outsideHoursSignalKind ? String(sceneState.outsideHoursSignalKind) : ""
    readonly property string effectiveWeatherKind: (outsideHoursSignalKind === "rain" || outsideHoursSignalKind === "snow" || outsideHoursSignalKind === "thunderstorm")
        ? outsideHoursSignalKind
        : weatherKind
    readonly property real cloudOpacity: sceneState && sceneState.cloudOpacity !== undefined ? sceneState.cloudOpacity : 0
    readonly property int cloudBandCount: sceneState && sceneState.cloudBandCount !== undefined ? sceneState.cloudBandCount : 0
    readonly property string cloudFamily: sceneState && sceneState.cloudFamily ? String(sceneState.cloudFamily) : "none"
    readonly property real cloudBreakFactor: sceneState && sceneState.cloudBreakFactor !== undefined ? sceneState.cloudBreakFactor : 1
    readonly property real celestialVeilOpacity: sceneState && sceneState.celestialVeilOpacity !== undefined ? sceneState.celestialVeilOpacity : 0
    readonly property real orbOcclusionOpacity: sceneState && sceneState.orbOcclusionOpacity !== undefined ? sceneState.orbOcclusionOpacity : 0
    readonly property int orbOcclusionBands: sceneState && sceneState.orbOcclusionBands !== undefined ? sceneState.orbOcclusionBands : 0
    readonly property real fogOpacity: sceneState && sceneState.fogOpacity !== undefined ? sceneState.fogOpacity : 0
    readonly property real fogDepth: sceneState && sceneState.fogDepth !== undefined ? sceneState.fogDepth : 0
    readonly property real humidity: sceneState && sceneState.humidity !== undefined ? sceneState.humidity : 0
    readonly property real humidityHaze: sceneState && sceneState.humidityHaze !== undefined ? sceneState.humidityHaze : 0
    readonly property real humidityBloom: sceneState && sceneState.humidityBloom !== undefined ? sceneState.humidityBloom : 0
    readonly property real rainDensity: sceneState && sceneState.rainDensity !== undefined ? sceneState.rainDensity : 0
    readonly property string rainBand: sceneState && sceneState.rainBand ? String(sceneState.rainBand) : "none"
    readonly property real snowDensity: sceneState && sceneState.snowDensity !== undefined ? sceneState.snowDensity : 0
    readonly property string snowBand: sceneState && sceneState.snowBand ? String(sceneState.snowBand) : "none"
    readonly property real storminess: sceneState && sceneState.storminess !== undefined ? sceneState.storminess : 0
    readonly property real effectiveRainDensity: (weatherKind === "rain" || weatherKind === "thunderstorm")
        ? rainDensity
        : ((outsideHoursSignalKind === "rain" || outsideHoursSignalKind === "thunderstorm") ? Math.max(0.38, rainDensity) : 0)
    readonly property string effectiveRainBand: (weatherKind === "rain" || weatherKind === "thunderstorm")
        ? rainBand
        : (outsideHoursSignalKind === "thunderstorm" ? "downpour" : (outsideHoursSignalKind === "rain" ? "drizzle" : "none"))
    readonly property real effectiveStorminess: weatherKind === "thunderstorm"
        ? storminess
        : (outsideHoursSignalKind === "thunderstorm" ? Math.max(0.42, storminess) : storminess)
    readonly property real cloudShadowStrength: sceneState && sceneState.cloudShadowStrength !== undefined ? sceneState.cloudShadowStrength : 0
    readonly property real clearingStrength: sceneState && sceneState.clearingStrength !== undefined ? sceneState.clearingStrength : 0
    readonly property real cloudSpeed: sceneState && sceneState.cloudSpeed !== undefined ? sceneState.cloudSpeed : 0.12
    readonly property real windDrift: sceneState && sceneState.windDrift !== undefined ? sceneState.windDrift : 0
    readonly property real motionStrength: sceneState && sceneState.motionStrength !== undefined ? sceneState.motionStrength : 0
    readonly property real lightningCadence: sceneState && sceneState.lightningCadence !== undefined ? sceneState.lightningCadence : 1
    readonly property bool lightningEnabled: sceneState && sceneState.lightning === true
    readonly property real cloudTravelDirection: Math.abs(windDrift) < 0.08 ? 1 : (windDrift > 0 ? 1 : -1)
    readonly property bool showClouds: cloudOpacity > 0.08
    readonly property bool showFog: fogOpacity > 0.05
    readonly property bool showRain: effectiveWeatherKind === "rain" || effectiveWeatherKind === "thunderstorm"
    readonly property bool showSnow: effectiveWeatherKind === "snow"
    readonly property real intensityFactor: root.clampRange(weatherIntensity, 0.4, 1.4)
    readonly property real sizeBudget: root.clampRange(0.42 + ((Math.min(root.width, root.height) - 72) / 120), 0.42, 1.04)
    readonly property real detailBudget: root.clampRange(
        sizeBudget * (cinematicWeather ? 1 : 0.76) * (0.72 + ((intensityFactor - 0.4) / 1.0) * 0.34),
        0.28,
        1.08
    )
    readonly property real motionBudget: reducedMotion ? 0.28 : root.clampRange((cinematicWeather ? 1 : 0.8) * (0.54 + ((intensityFactor - 0.4) / 1.0) * 0.4), 0.3, 1)
    readonly property int rainParticleCount: showRain
        ? Math.max(6, Math.round(
            (effectiveRainBand === "drizzle" ? Math.max(36, 44 + (effectiveRainDensity * 30)) : (effectiveRainBand === "downpour" ? Math.max(72, 82 + (effectiveRainDensity * 38)) : Math.max(40, 46 + (effectiveRainDensity * 28))))
            * detailBudget
        ))
        : 0
    readonly property real rainAngleDegrees: ((windDrift * (14 + (windStrength * 34) + (effectiveStorminess * 10))) + (effectiveStorminess * 8)) * (0.38 + (motionBudget * 0.62))
    readonly property int snowParticleCount: showSnow
        ? Math.max(6, Math.round(
            (snowBand === "flurries" ? Math.max(16, 18 + (snowDensity * 16)) : (snowBand === "heavy" ? Math.max(40, 48 + (snowDensity * 30)) : Math.max(28, 32 + (snowDensity * 22))))
            * detailBudget
        ))
        : 0
    readonly property var normalizedSunRect: root.normalizeRect(root.sunRect)
    readonly property var normalizedMoonRect: root.normalizeRect(root.moonRect)
    readonly property var lightSourceRect: root.normalizedSunRect.visible
        ? root.normalizedSunRect
        : (root.normalizedMoonRect.visible
            ? root.normalizedMoonRect
            : root.fallbackOcclusionRect())
    readonly property bool lightSourceVisible: root.lightSourceRect.visible
    readonly property bool lightSourceIsSun: root.normalizedSunRect.visible
    readonly property real lightSourceCenterX: root.lightSourceRect.x + (root.lightSourceRect.width / 2)
    readonly property real lightSourceCenterY: root.lightSourceRect.y + (root.lightSourceRect.height / 2)
    readonly property real windStrength: root.clampUnit((Math.abs(windDrift) * 0.34) + (motionStrength * 0.82))
    readonly property real windShiftSpan: root.width * (0.05 + (windStrength * 0.2)) * (0.26 + (motionBudget * 0.74))
    readonly property real occlusionShiftSpan: Math.max(root.cardScale * 0.04, root.occlusionTargetRect.width * (0.14 + (windStrength * 0.18))) * (0.24 + (motionBudget * 0.76))
    readonly property bool showRainCurtain: showRain
        && detailBudget > 0.3
    readonly property bool showSnowNearField: showSnow && snowBand !== "flurries" && detailBudget > 0.4
    readonly property bool showFogSkyVeil: showFog && fogDepth > 0.3 && detailBudget > 0.36
    readonly property bool showHighCloudWisps: showClouds && cloudFamily === "wispy" && detailBudget > 0.52
    readonly property bool showStormShelf: showClouds && cloudFamily === "shelf" && detailBudget > 0.46
    readonly property bool showCumulusPuffs: showClouds && cloudFamily === "cumulus"
    readonly property bool showLayeredStratus: showClouds && (cloudFamily === "stratus" || cloudFamily === "veil")
    readonly property bool showWispyTrails: showClouds && cloudFamily === "wispy"
    readonly property bool showShelfUndercut: showClouds && cloudFamily === "shelf"
    readonly property bool showCloudShadows: cloudShadowStrength > 0.05
        && root.lightSourceIsSun
        && root.detailBudget > 0.34
    readonly property int cloudShadowBandCount: showCloudShadows
        ? Math.max(1, Math.round((1 + (cloudShadowStrength * 5)) * detailBudget))
        : 0
    readonly property bool showWindStreaks: detailBudget > 0.34
        && windStrength > 0.18
        && !showRain
        && (showClouds || showFog || showRain || showSnow || storminess > 0.22)
    readonly property int windStreakCount: showWindStreaks
        ? Math.max(2, Math.round((2 + (windStrength * 7) + (storminess * 2)) * detailBudget))
        : 0
    readonly property bool showHumidityGlow: (humidityHaze > 0.08 || humidityBloom > 0.06)
        && root.lightSourceVisible
        && detailBudget > 0.3
    readonly property bool showClearingMist: clearingStrength > 0.08
        && !showRain
        && !showSnow
        && detailBudget > 0.3
    readonly property real orbLightStrength: root.lightSourceVisible
        ? root.clampUnit(
            (root.lightSourceIsSun ? 0.34 : 0.22)
            + (root.twilightActive ? (root.lightSourceIsSun ? 0.08 : 0.04) : 0)
            - (root.cloudOpacity * (root.lightSourceIsSun ? 0.18 : 0.1))
            - (root.orbOcclusionOpacity * 0.22)
            - (root.fogOpacity * 0.34)
            - (root.effectiveRainDensity * 0.26)
            - (root.effectiveStorminess * 0.18)
        )
        : 0
    readonly property color cloudLiningColor: root.lightSourceVisible
        ? root.blendColors(root.orbLightColor, root.cloudHighlightColor, root.lightSourceIsSun ? 0.22 : 0.4)
        : root.blendColors(root.cloudHighlightColor, root.cloudColor, (root.effectiveWeatherKind === "rain" || root.effectiveWeatherKind === "thunderstorm") ? 0.08 : 0.22)
    readonly property color cloudGlowColor: root.lightSourceVisible
        ? root.blendColors(root.orbLightAccentColor, root.twilightWarmColor, root.lightSourceIsSun ? 0.16 : 0.08)
        : root.blendColors(root.cloudShadowColor, root.cloudColor, (root.effectiveWeatherKind === "rain" || root.effectiveWeatherKind === "thunderstorm") ? 0.34 : 0.18)
    readonly property real heatStrength: root.clampUnit(
        root.summerStrength
        * (root.lightSourceIsSun ? 1 : 0)
        * (root.twilightActive ? 0.54 : 1)
        * (root.effectiveWeatherKind === "clear" ? 1 : (root.effectiveWeatherKind === "cloudy" ? Math.max(0, 0.58 - (root.cloudOpacity * 1.1)) : 0))
        * (1 - (root.fogOpacity * 0.92))
        * (1 - (root.effectiveRainDensity * 0.8))
        * (1 - (root.snowDensity * 0.9))
    )
    readonly property bool showHeatShimmer: root.heatStrength > 0.08 && root.detailBudget > 0.34 && root.lightSourceVisible
    readonly property real lightningFlashSide: root.cloudTravelDirection > 0 ? 0.72 : 0.28
    readonly property int farFogBandCount: showFog ? Math.max(1, Math.round((fogDepth > 0.7 ? 3 : 2) * detailBudget)) : 0
    readonly property int midFogBandCount: showFog ? Math.max(1, Math.round((fogDepth > 0.42 ? 2 : 1) * detailBudget)) : 0
    readonly property int nearFogBandCount: showFog ? Math.max(1, Math.round((fogDepth > 0.66 ? 3 : 2) * detailBudget)) : 0
    readonly property bool orbMaskActive: root.orbOcclusionOpacity > 0.08
        && root.orbOcclusionBands > 0
        && root.occlusionTargetRect.visible
        && root.occlusionTargetRect.width > 0
        && root.occlusionTargetRect.height > 0
    readonly property var occlusionTargetRect: root.normalizedSunRect.visible
        ? root.normalizedSunRect
        : (root.normalizedMoonRect.visible
            ? root.normalizedMoonRect
            : root.fallbackOcclusionRect())
    readonly property color cloudTopTintColor: root.twilightActive
        ? root.blendColors(root.cloudHighlightColor, root.twilightCoolColor, root.clampUnit((root.twilightCoolness * 0.42) + (root.windStrength * 0.06)))
        : ((root.effectiveWeatherKind === "rain" || root.effectiveWeatherKind === "thunderstorm")
            ? root.blendColors(root.cloudHighlightColor, root.cloudColor, 0.46)
            : root.cloudHighlightColor)
    readonly property color cloudWarmTintColor: root.twilightActive
        ? root.blendColors(root.cloudColor, root.twilightWarmColor, root.clampUnit(root.twilightWarmth * 0.46))
        : ((root.effectiveWeatherKind === "rain" || root.effectiveWeatherKind === "thunderstorm")
            ? root.blendColors(root.cloudColor, root.cloudShadowColor, 0.12)
            : root.cloudColor)
    readonly property color cloudUndersideTintColor: root.twilightActive
        ? root.blendColors(root.cloudShadowColor, root.twilightCoolColor, root.clampUnit(root.twilightCoolness * 0.28))
        : root.cloudShadowColor
    readonly property color fogFarTintColor: root.twilightActive
        ? root.blendColors(root.fogColor, root.twilightCoolColor, root.clampUnit(root.twilightCoolness * 0.24))
        : root.fogColor
    readonly property color fogNearTintColor: root.twilightActive
        ? root.blendColors(root.fogColor, root.twilightWarmColor, root.clampUnit(root.twilightWarmth * 0.24))
        : root.fogColor
    readonly property color cloudShadowTintColor: root.blendColors(root.cloudShadowColor, root.fogFarTintColor, 0.24 + (root.humidityHaze * 0.18))
    readonly property color humidityGlowColor: root.blendColors(root.cloudGlowColor, root.fogColor, 0.44 + (root.humidityHaze * 0.18))
    readonly property color clearingMistColor: root.blendColors(root.fogNearTintColor, root.cloudGlowColor, 0.12 + (root.clearingStrength * 0.14))
    readonly property color rainVeilTopColor: root.blendColors(root.cloudShadowColor, root.precipitationColor, 0.08 + (root.effectiveRainDensity * 0.06))
    readonly property color rainVeilMidColor: root.blendColors(root.cloudShadowColor, root.precipitationColor, 0.14 + (root.effectiveRainDensity * 0.1))
    readonly property color rainVeilBottomColor: root.blendColors(root.cloudShadowColor, root.precipitationColor, 0.2 + (root.effectiveRainDensity * 0.14))
    readonly property color snowVeilTopColor: root.blendColors(root.fogFarTintColor, root.snowColor, 0.42 + (root.snowDensity * 0.1))
    readonly property color snowVeilBottomColor: root.blendColors(root.fogNearTintColor, root.snowColor, 0.56 + (root.snowDensity * 0.12))
    readonly property color fogVeilTopColor: root.blendColors(root.fogFarTintColor, root.cloudShadowColor, 0.18 + (root.fogDepth * 0.08))
    readonly property color fogVeilBottomColor: root.blendColors(root.fogNearTintColor, root.fogColor, 0.46 + (root.fogDepth * 0.14))

    visible: showClouds || showFog || showRain || showSnow || lightningEnabled || showHeatShimmer || showWindStreaks || showCloudShadows || showHumidityGlow || showClearingMist
    clip: true

    function clampUnit(value) {
        return Math.max(0, Math.min(1, value));
    }

    function clampRange(value, minimum, maximum) {
        return Math.max(minimum, Math.min(maximum, value));
    }

    function blendColors(baseColor, tintColor, amount) {
        const mix = clampUnit(amount);

        return Qt.rgba(
            (baseColor.r * (1 - mix)) + (tintColor.r * mix),
            (baseColor.g * (1 - mix)) + (tintColor.g * mix),
            (baseColor.b * (1 - mix)) + (tintColor.b * mix),
            (baseColor.a * (1 - mix)) + (tintColor.a * mix)
        );
    }

    function withAlpha(colorValue, alphaValue) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, alphaValue);
    }

    function sampleUnit(index, salt) {
        const raw = Math.sin((zoneSeed + (index * 92821) + (salt * 68917)) * 0.000013) * 43758.5453123;
        return raw - Math.floor(raw);
    }

    function normalizeRect(rectValue) {
        const source = rectValue || {};
        const rectWidth = Math.max(0, Number(source.width || 0));
        const rectHeight = Math.max(0, Number(source.height || 0));

        return {
            "visible": source.visible === true && rectWidth > 0 && rectHeight > 0,
            "x": Number(source.x || 0),
            "y": Number(source.y || 0),
            "width": rectWidth,
            "height": rectHeight
        };
    }

    function fallbackOcclusionRect() {
        const fallbackWidth = Math.max(root.width * 0.34, root.cardScale * 0.44);
        const fallbackHeight = Math.max(root.height * 0.3, root.cardScale * 0.26);

        return {
            "visible": false,
            "x": root.width - fallbackWidth,
            "y": root.height * 0.08,
            "width": fallbackWidth,
            "height": fallbackHeight
        };
    }

    Rectangle {
        id: rainVeilLayer

        objectName: "rainVeilLayerItem"
        anchors.fill: parent
        z: 1
        visible: root.showRain
        opacity: 0.32 + (root.effectiveRainDensity * 0.3) + (root.effectiveStorminess * 0.08)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.rainVeilTopColor, 0.94)
            }
            GradientStop {
                position: 0.58
                color: root.withAlpha(root.rainVeilMidColor, 0.72)
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.rainVeilBottomColor, 0.52)
            }
        }
    }

    Rectangle {
        id: snowVeilLayer

        objectName: "snowVeilLayerItem"
        anchors.fill: parent
        z: 1
        visible: root.showSnow
        opacity: 0.2 + (root.snowDensity * 0.16)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.snowVeilTopColor, 0.42)
            }
            GradientStop {
                position: 0.6
                color: root.withAlpha(root.snowVeilTopColor, 0.18)
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.snowVeilBottomColor, 0.34)
            }
        }
    }

    Rectangle {
        id: fogVeilLayer

        objectName: "fogVeilLayerItem"
        anchors.fill: parent
        z: 1
        visible: root.showFog
        opacity: 0.46 + (root.fogOpacity * 0.26) + (root.fogDepth * 0.14)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.fogVeilTopColor, 0.82)
            }
            GradientStop {
                position: 0.56
                color: root.withAlpha(root.fogVeilTopColor, 0.52)
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.fogVeilBottomColor, 0.72)
            }
        }
    }

    Rectangle {
        id: fogBankLayer

        objectName: "fogBankLayerItem"
        anchors.left: parent.left
        anchors.right: parent.right
        y: parent.height * 0.34
        height: parent.height * (0.24 + (root.fogDepth * 0.1))
        z: 2
        visible: root.showFog
        opacity: 0.26 + (root.fogOpacity * 0.18) + (root.fogDepth * 0.1)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.fogNearTintColor, 0)
            }
            GradientStop {
                position: 0.42
                color: root.withAlpha(root.blendColors(root.fogNearTintColor, root.fogColor, 0.28), 0.72)
            }
            GradientStop {
                position: 0.76
                color: root.withAlpha(root.blendColors(root.fogNearTintColor, root.fogColor, 0.16), 0.48)
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.fogNearTintColor, 0)
            }
        }
    }

    Item {
        id: cloudShadowLayer

        objectName: "cloudShadowLayerItem"
        anchors.fill: parent
        visible: root.showCloudShadows

        Repeater {
            model: root.cloudShadowBandCount

            delegate: Rectangle {
                required property int index

                readonly property real bandWidth: root.width * (0.34 + (root.sampleUnit(index + 71, 1) * 0.3))
                readonly property real bandHeight: root.height * (0.14 + (root.sampleUnit(index + 71, 2) * 0.12))
                readonly property real startY: root.height * (0.24 + (root.sampleUnit(index + 71, 3) * 0.46))
                readonly property real shadowOpacity: root.cloudShadowStrength * (0.06 + (root.sampleUnit(index + 71, 4) * 0.08))
                readonly property int travelDuration: Math.round(
                    7200
                    - (root.windStrength * 1800)
                    + (root.sampleUnit(index + 71, 5) * 1800)
                )

                width: bandWidth
                height: bandHeight
                radius: height / 2
                y: startY
                opacity: shadowOpacity
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.cloudShadowTintColor, 0)
                    }
                    GradientStop {
                        position: 0.5
                        color: root.withAlpha(root.cloudShadowTintColor, shadowOpacity)
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.cloudShadowTintColor, 0)
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: cloudShadowLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? -bandWidth - (root.width * 0.18) : root.width + (root.width * 0.18)
                        to: root.cloudTravelDirection > 0 ? root.width + (root.width * 0.12) : -bandWidth - (root.width * 0.12)
                        duration: Math.max(2800, travelDuration)
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    Item {
        id: cloudLayer

        objectName: "cloudLayerItem"
        anchors.fill: parent
        visible: root.showClouds

        Repeater {
            model: Math.max(0, Math.round(root.cloudBandCount * root.detailBudget))

            delegate: Item {
                id: cloudCluster

                required property int index

                readonly property real familyWidthBias: root.cloudFamily === "wispy"
                    ? 0.26
                    : (root.cloudFamily === "cumulus" ? 0.08 : (root.cloudFamily === "shelf" ? 0.32 : 0.16))
                readonly property real familyHeightBias: root.cloudFamily === "wispy"
                    ? -0.04
                    : (root.cloudFamily === "cumulus" ? 0.05 : (root.cloudFamily === "shelf" ? 0.02 : 0.03))
                readonly property real widthFactor: (0.2 + familyWidthBias + ((1 - root.cloudBreakFactor) * 0.22)) + (root.sampleUnit(index + 1, 1) * (0.18 + (root.cloudBreakFactor * 0.24)))
                readonly property real heightFactor: (0.1 + familyHeightBias + ((1 - root.cloudBreakFactor) * 0.06)) + (root.sampleUnit(index + 1, 2) * (root.cloudFamily === "wispy" ? 0.04 : 0.08))
                readonly property real startY: (root.sampleUnit(index + 1, 3) * root.height * (0.3 + (root.cloudBreakFactor * 0.22))) - (root.height * 0.06)
                readonly property real baseOpacity: root.cloudOpacity * (0.16 + ((1 - root.cloudBreakFactor) * 0.1) + (root.sampleUnit(index + 1, 4) * 0.16))
                readonly property real travelDuration: (root.width * 21000) / Math.max(
                    36,
                    root.cardScale * (0.34 + root.cloudSpeed + (root.windStrength * 0.38) + (root.sampleUnit(index + 1, 5) * 0.16))
                )
                readonly property real warmEdgeStrength: root.twilightActive
                    ? root.clampUnit((root.twilightWarmth * 0.12) + ((startY / Math.max(1, root.height)) * root.twilightWarmth * 0.42))
                    : 0
                readonly property real coolEdgeStrength: root.twilightActive
                    ? root.clampUnit((root.twilightCoolness * 0.16) + ((1 - (startY / Math.max(1, root.height))) * root.twilightCoolness * 0.34))
                    : 0
                readonly property real clusterCenterX: x + (width / 2)
                readonly property real clusterCenterY: y + (height * 0.42)
                readonly property real lightDx: root.lightSourceCenterX - clusterCenterX
                readonly property real lightDy: root.lightSourceCenterY - clusterCenterY
                readonly property real lightDistance: Math.sqrt((lightDx * lightDx) + (lightDy * lightDy))
                readonly property real lightProximity: root.lightSourceVisible
                    ? root.clampUnit(1 - (lightDistance / Math.max(root.cardScale * 1.4, root.width * 0.9)))
                    : 0
                readonly property real lightSideBias: root.lightSourceVisible
                    ? root.clampRange(lightDx / Math.max(1, root.width * 0.38), -1, 1)
                    : 0
                readonly property real lightTopBias: root.lightSourceVisible
                    ? root.clampUnit((clusterCenterY - root.lightSourceCenterY) / Math.max(1, root.height * 0.42))
                    : 0
                readonly property real silverLiningStrength: root.orbLightStrength * root.clampUnit(
                    (0.18 + (lightProximity * 0.52) + ((1 - root.cloudBreakFactor) * 0.08))
                    * (0.76 + (Math.abs(lightSideBias) * 0.18))
                )
                readonly property real glowBandStrength: silverLiningStrength * (root.lightSourceIsSun ? 0.64 : 0.42)
                readonly property bool isWispyFamily: root.cloudFamily === "wispy"
                readonly property bool isCumulusFamily: root.cloudFamily === "cumulus"
                readonly property bool isStratusFamily: root.cloudFamily === "stratus"
                readonly property bool isVeilFamily: root.cloudFamily === "veil"
                readonly property bool isShelfFamily: root.cloudFamily === "shelf"
                readonly property real silhouetteDensity: root.clampUnit((1 - root.cloudBreakFactor) * 0.78)

                width: Math.max(root.width * widthFactor, root.cardScale * 0.32)
                height: Math.max(root.height * heightFactor, root.cardScale * 0.14)
                y: startY
                opacity: baseOpacity

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: cloudLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0
                            ? -cloudCluster.width - (root.width * 0.08)
                            : root.width + (root.width * 0.08)
                        to: root.cloudTravelDirection > 0
                            ? root.width + (root.width * 0.08)
                            : -cloudCluster.width - (root.width * 0.08)
                        duration: Math.round(cloudCluster.travelDuration * (1 - (root.motionBudget * 0.12)))
                        easing.type: Easing.Linear
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.74
                    height: parent.height * (cloudCluster.isWispyFamily ? 0.42 : (cloudCluster.isShelfFamily ? 0.54 : (cloudCluster.isVeilFamily ? 0.66 : 0.58)))
                    radius: height / 2
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(
                                root.blendColors(
                                    root.blendColors(root.cloudTopTintColor, root.twilightCoolColor, cloudCluster.coolEdgeStrength * 0.34),
                                    root.cloudLiningColor,
                                    cloudCluster.silverLiningStrength * 0.34
                                ),
                                cloudCluster.baseOpacity * (0.78 - (root.cloudBreakFactor * 0.12))
                            )
                        }
                        GradientStop {
                            position: 0.58
                            color: root.withAlpha(
                                root.blendColors(
                                    root.blendColors(root.cloudWarmTintColor, root.twilightWarmColor, cloudCluster.warmEdgeStrength * 0.22),
                                    root.cloudGlowColor,
                                    cloudCluster.glowBandStrength * 0.22
                                ),
                                cloudCluster.baseOpacity * 0.98
                            )
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(
                                root.blendColors(root.cloudUndersideTintColor, root.twilightWarmColor, cloudCluster.warmEdgeStrength * 0.14),
                                cloudCluster.baseOpacity * (0.7 + ((1 - root.cloudBreakFactor) * 0.12))
                            )
                        }
                    }
                }

                Rectangle {
                    objectName: "cumulusPuffShapeItem"
                    visible: cloudCluster.isCumulusFamily
                    width: parent.width * 0.28
                    height: parent.height * 0.64
                    radius: height / 2
                    x: parent.width * 0.02
                    y: parent.height * 0.18
                    color: root.withAlpha(
                        root.blendColors(root.cloudTopTintColor, root.cloudLiningColor, cloudCluster.silverLiningStrength * 0.26),
                        cloudCluster.baseOpacity * 0.84
                    )
                }

                Rectangle {
                    visible: cloudCluster.isCumulusFamily
                    width: parent.width * 0.32
                    height: parent.height * 0.72
                    radius: height / 2
                    x: parent.width * 0.28
                    y: parent.height * 0.02
                    color: root.withAlpha(
                        root.blendColors(root.cloudWarmTintColor, root.cloudGlowColor, cloudCluster.glowBandStrength * 0.18),
                        cloudCluster.baseOpacity * 0.92
                    )
                }

                Rectangle {
                    visible: cloudCluster.isCumulusFamily
                    width: parent.width * 0.24
                    height: parent.height * 0.52
                    radius: height / 2
                    x: parent.width * 0.66
                    y: parent.height * 0.16
                    color: root.withAlpha(
                        root.blendColors(root.cloudTopTintColor, root.cloudLiningColor, cloudCluster.silverLiningStrength * 0.22),
                        cloudCluster.baseOpacity * 0.82
                    )
                }

                Rectangle {
                    objectName: "stratusLayerShapeItem"
                    visible: cloudCluster.isStratusFamily || cloudCluster.isVeilFamily
                    width: parent.width * (cloudCluster.isVeilFamily ? 0.94 : 0.88)
                    height: parent.height * (cloudCluster.isVeilFamily ? 0.26 : 0.2)
                    radius: height / 2
                    x: parent.width * 0.03
                    y: parent.height * (cloudCluster.isVeilFamily ? 0.18 : 0.12)
                    color: root.withAlpha(
                        root.blendColors(root.cloudTopTintColor, root.cloudLiningColor, cloudCluster.silverLiningStrength * 0.18),
                        cloudCluster.baseOpacity * (cloudCluster.isVeilFamily ? 0.46 : 0.64)
                    )
                }

                Rectangle {
                    visible: cloudCluster.isStratusFamily || cloudCluster.isVeilFamily
                    width: parent.width * (cloudCluster.isVeilFamily ? 0.82 : 0.76)
                    height: parent.height * (cloudCluster.isVeilFamily ? 0.18 : 0.16)
                    radius: height / 2
                    x: parent.width * 0.1
                    y: parent.height * 0.34
                    color: root.withAlpha(
                        root.blendColors(root.cloudWarmTintColor, root.cloudUndersideTintColor, 0.28),
                        cloudCluster.baseOpacity * (cloudCluster.isVeilFamily ? 0.34 : 0.52)
                    )
                }

                Rectangle {
                    objectName: "wispyTrailShapeItem"
                    visible: cloudCluster.isWispyFamily
                    width: parent.width * 0.92
                    height: Math.max(2, parent.height * 0.12)
                    radius: height / 2
                    x: parent.width * 0.02
                    y: parent.height * 0.2
                    rotation: root.cloudTravelDirection * -8
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudTopTintColor, 0)
                        }
                        GradientStop {
                            position: 0.48
                            color: root.withAlpha(
                                root.blendColors(root.cloudTopTintColor, root.cloudLiningColor, cloudCluster.silverLiningStrength * 0.2),
                                cloudCluster.baseOpacity * 0.54
                            )
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudTopTintColor, 0)
                        }
                    }
                }

                Rectangle {
                    visible: cloudCluster.isWispyFamily
                    width: parent.width * 0.58
                    height: Math.max(2, parent.height * 0.08)
                    radius: height / 2
                    x: root.cloudTravelDirection > 0 ? parent.width * 0.3 : parent.width * 0.12
                    y: parent.height * 0.38
                    rotation: root.cloudTravelDirection * -10
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudWarmTintColor, 0)
                        }
                        GradientStop {
                            position: 0.52
                            color: root.withAlpha(root.cloudWarmTintColor, cloudCluster.baseOpacity * 0.34)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudWarmTintColor, 0)
                        }
                    }
                }

                Rectangle {
                    objectName: "shelfUndercutShapeItem"
                    visible: cloudCluster.isShelfFamily
                    width: parent.width * 0.9
                    height: parent.height * 0.24
                    radius: height / 2
                    x: parent.width * 0.04
                    y: parent.height * 0.44
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.14)
                        }
                        GradientStop {
                            position: 0.42
                            color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.64)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.34)
                        }
                    }
                }

                Rectangle {
                    visible: cloudCluster.isShelfFamily
                    width: parent.width * 0.18
                    height: parent.height * 0.22
                    radius: height / 2
                    x: parent.width * 0.16
                    y: parent.height * 0.58
                    color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.48)
                }

                Rectangle {
                    visible: cloudCluster.isShelfFamily
                    width: parent.width * 0.16
                    height: parent.height * 0.18
                    radius: height / 2
                    x: parent.width * 0.62
                    y: parent.height * 0.56
                    color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.42)
                }

                Rectangle {
                    visible: !root.showLayeredStratus
                    width: parent.width * 0.42
                    height: parent.height * 0.7
                    radius: height / 2
                    x: parent.width * 0.12
                    y: parent.height * 0.06
                    color: root.withAlpha(
                        root.blendColors(root.cloudTopTintColor, root.twilightWarmColor, cloudCluster.warmEdgeStrength * 0.12),
                        cloudCluster.baseOpacity * (root.showLayeredStratus ? 0.66 : 0.9)
                    )
                }

                Rectangle {
                    visible: !root.showLayeredStratus
                    width: parent.width * 0.38
                    height: parent.height * 0.62
                    radius: height / 2
                    x: parent.width * 0.52
                    y: parent.height * 0.02
                    color: root.withAlpha(
                        root.blendColors(root.cloudWarmTintColor, root.twilightWarmColor, cloudCluster.warmEdgeStrength * 0.18),
                        cloudCluster.baseOpacity * (root.showLayeredStratus ? 0.62 : 0.88)
                    )
                }

                Rectangle {
                    visible: root.showLayeredStratus
                    width: parent.width * 0.94
                    height: parent.height * 0.24
                    radius: height * 0.42
                    x: parent.width * 0.02
                    y: parent.height * 0.12
                    rotation: root.cloudTravelDirection * -2
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudTopTintColor, 0)
                        }
                        GradientStop {
                            position: 0.22
                            color: root.withAlpha(root.cloudTopTintColor, cloudCluster.baseOpacity * 0.26)
                        }
                        GradientStop {
                            position: 0.68
                            color: root.withAlpha(root.cloudWarmTintColor, cloudCluster.baseOpacity * 0.52)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudWarmTintColor, 0)
                        }
                    }
                }

                Rectangle {
                    visible: root.showLayeredStratus
                    width: parent.width * 0.74
                    height: parent.height * 0.18
                    radius: height * 0.46
                    x: parent.width * 0.18
                    y: parent.height * 0.02
                    rotation: root.cloudTravelDirection * -4
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudTopTintColor, 0)
                        }
                        GradientStop {
                            position: 0.34
                            color: root.withAlpha(root.cloudTopTintColor, cloudCluster.baseOpacity * 0.24)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudTopTintColor, 0)
                        }
                    }
                }

                Rectangle {
                    visible: root.showLayeredStratus
                    width: parent.width * 0.62
                    height: parent.height * 0.16
                    radius: height * 0.48
                    x: parent.width * 0.08
                    y: parent.height * 0.3
                    rotation: root.cloudTravelDirection * 3
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudUndersideTintColor, 0)
                        }
                        GradientStop {
                            position: 0.28
                            color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.18)
                        }
                        GradientStop {
                            position: 0.74
                            color: root.withAlpha(root.cloudUndersideTintColor, cloudCluster.baseOpacity * 0.34)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudUndersideTintColor, 0)
                        }
                    }
                }

                Rectangle {
                    visible: !root.showLayeredStratus
                    width: parent.width * 0.58
                    height: Math.max(2, parent.height * 0.16)
                    radius: height / 2
                    x: parent.width * 0.18
                    y: parent.height * 0.12
                    color: root.withAlpha(root.cloudTopTintColor, cloudCluster.baseOpacity * 0.34)
                }

                Rectangle {
                    visible: root.lightSourceVisible && cloudCluster.silverLiningStrength > 0.04
                    width: parent.width * (root.cloudFamily === "shelf" ? 0.48 : 0.34)
                    height: Math.max(2, parent.height * (0.14 + (cloudCluster.lightTopBias * 0.06)))
                    radius: height / 2
                    x: cloudCluster.lightSideBias >= 0
                        ? parent.width * (0.38 + (cloudCluster.lightSideBias * 0.16))
                        : parent.width * (0.06 + ((cloudCluster.lightSideBias + 1) * 0.12))
                    y: parent.height * (0.06 + ((1 - cloudCluster.lightTopBias) * 0.08))
                    rotation: cloudCluster.lightSideBias * 10
                    color: root.withAlpha(
                        root.cloudLiningColor,
                        cloudCluster.silverLiningStrength * (0.44 + (root.lightSourceIsSun ? 0.22 : 0.08))
                    )
                }

                Rectangle {
                    visible: root.lightSourceVisible && cloudCluster.glowBandStrength > 0.03
                    width: parent.width * 0.52
                    height: Math.max(2, parent.height * 0.11)
                    radius: height / 2
                    x: parent.width * 0.18
                    y: parent.height * (0.18 + ((1 - cloudCluster.lightTopBias) * 0.08))
                    color: root.withAlpha(root.cloudGlowColor, cloudCluster.glowBandStrength * 0.34)
                }

                Rectangle {
                    visible: root.twilightActive && cloudCluster.warmEdgeStrength > 0.04
                    width: parent.width * 0.56
                    height: Math.max(2, parent.height * 0.12)
                    radius: height / 2
                    x: parent.width * 0.24
                    y: parent.height * 0.48
                    color: root.withAlpha(
                        root.blendColors(root.twilightWarmColor, root.cloudHighlightColor, 0.26),
                        cloudCluster.baseOpacity * (0.12 + (cloudCluster.warmEdgeStrength * 0.16))
                    )
                }
            }
        }
    }

    Item {
        id: highCloudLayer

        objectName: "highCloudLayerItem"
        anchors.fill: parent
        visible: root.showHighCloudWisps

        Repeater {
            model: Math.max(2, Math.round(3 * root.detailBudget))

            delegate: Rectangle {
                required property int index

                readonly property real bandOpacity: root.cloudOpacity * (0.08 + (root.sampleUnit(index + 41, 1) * 0.06))
                readonly property real bandWidth: root.width * (0.42 + (root.sampleUnit(index + 41, 2) * 0.26))
                readonly property real bandHeight: Math.max(root.cardScale * 0.016, root.height * (0.018 + (root.sampleUnit(index + 41, 3) * 0.012)))
                readonly property real startY: root.height * (0.08 + (root.sampleUnit(index + 41, 4) * 0.16))

                width: bandWidth
                height: bandHeight
                radius: height / 2
                y: startY
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.cloudTopTintColor, 0)
                    }
                    GradientStop {
                        position: 0.46
                        color: root.withAlpha(
                            root.blendColors(root.cloudTopTintColor, root.cloudLiningColor, root.orbLightStrength * 0.28),
                            bandOpacity
                        )
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.cloudTopTintColor, 0)
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: highCloudLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? -bandWidth : root.width
                        to: root.cloudTravelDirection > 0 ? root.width : -bandWidth
                        duration: 5600 + Math.round((1 - root.motionBudget) * 1400) + Math.round(root.sampleUnit(index + 41, 5) * 1200)
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    Item {
        id: windLayer

        objectName: "windLayerItem"
        anchors.fill: parent
        visible: root.showWindStreaks

        Repeater {
            model: root.windStreakCount

            delegate: Rectangle {
                required property int index

                readonly property real streakWidth: root.width * (0.14 + (root.windStrength * 0.18) + (root.sampleUnit(index + 51, 1) * 0.08))
                readonly property real streakHeight: Math.max(root.cardScale * 0.012, root.height * (0.012 + (root.sampleUnit(index + 51, 2) * 0.012)))
                readonly property real streakOpacity: 0.04
                    + (root.windStrength * 0.08)
                    + (root.fogOpacity * 0.04)
                    + (root.rainDensity * 0.03)
                    + (root.sampleUnit(index + 51, 3) * 0.04)
                readonly property real startY: root.height * (0.14 + (root.sampleUnit(index + 51, 4) * 0.5))
                readonly property real travelSpan: root.width * (0.22 + (root.windStrength * 0.34) + (root.sampleUnit(index + 51, 5) * 0.08))
                readonly property int travelDuration: Math.round(
                    3400
                    - (root.windStrength * 1500)
                    - (root.motionBudget * 420)
                    + (root.sampleUnit(index + 51, 6) * 700)
                )

                width: streakWidth
                height: streakHeight
                radius: height / 2
                y: startY
                rotation: (root.windDrift * 12) + ((root.sampleUnit(index + 51, 7) - 0.5) * 6)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.cloudTopTintColor, 0)
                    }
                    GradientStop {
                        position: 0.48
                        color: root.withAlpha(
                            root.blendColors(root.cloudLiningColor, root.fogNearTintColor, 0.26 + (root.fogOpacity * 0.16)),
                            streakOpacity
                        )
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.cloudTopTintColor, 0)
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: windLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? -streakWidth - (root.width * 0.12) : root.width + (root.width * 0.12)
                        to: root.cloudTravelDirection > 0 ? root.width + travelSpan : -streakWidth - travelSpan
                        duration: Math.max(900, travelDuration)
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    Rectangle {
        id: stormShelfLayer

        objectName: "stormShelfLayerItem"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.22
        visible: root.showStormShelf
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.cloudUndersideTintColor, root.cloudOpacity * 0.42)
            }
            GradientStop {
                position: 0.46
                color: root.withAlpha(
                    root.blendColors(root.cloudWarmTintColor, root.cloudGlowColor, root.orbLightStrength * 0.22),
                    root.cloudOpacity * 0.26
                )
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.cloudUndersideTintColor, 0)
            }
        }

        Rectangle {
            width: parent.width * 0.32
            height: Math.max(2, parent.height * 0.12)
            radius: height / 2
            x: parent.width * (root.lightningFlashSide - 0.16)
            y: parent.height * 0.08
            visible: root.orbLightStrength > 0.04
            color: root.withAlpha(root.cloudLiningColor, root.orbLightStrength * 0.24)
        }
    }

    Rectangle {
        id: celestialVeil

        objectName: "celestialVeilItem"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.56
        visible: root.celestialVeilOpacity > 0.02
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.cloudColor, root.celestialVeilOpacity * 0.74)
            }
            GradientStop {
                position: 0.56
                color: root.withAlpha(root.cloudColor, root.celestialVeilOpacity * 0.28)
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.cloudColor, 0)
            }
        }
    }

    Item {
        id: humidityGlowLayer

        objectName: "humidityGlowLayerItem"
        anchors.fill: parent
        visible: root.showHumidityGlow

        Rectangle {
            width: Math.max(root.cardScale * 0.34, root.width * (0.3 + (root.humidityBloom * 0.28)))
            height: width
            radius: width / 2
            x: root.clampRange(root.lightSourceCenterX - (width / 2), -width * 0.12, root.width - (width * 0.88))
            y: root.clampRange(root.lightSourceCenterY - (height / 2), -height * 0.18, root.height - (height * 0.72))
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.humidityGlowColor, root.humidityBloom * 0.12)
                }
                GradientStop {
                    position: 0.42
                    color: root.withAlpha(root.humidityGlowColor, root.humidityBloom * 0.06)
                }
                GradientStop {
                    position: 1
                    color: root.withAlpha(root.humidityGlowColor, 0)
                }
            }
        }

        Rectangle {
            width: root.width * 1.14
            height: root.height * (0.18 + (root.humidityHaze * 0.12))
            radius: height / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -height * 0.24
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.humidityGlowColor, 0)
                }
                GradientStop {
                    position: 0.5
                    color: root.withAlpha(root.humidityGlowColor, root.humidityHaze * 0.08)
                }
                GradientStop {
                    position: 1
                    color: root.withAlpha(root.humidityGlowColor, root.humidityHaze * 0.18)
                }
            }
        }
    }

    Item {
        id: celestialOcclusionLayer

        objectName: "celestialOcclusionLayerItem"
        readonly property real targetLocalX: root.occlusionTargetRect.visible ? root.occlusionTargetRect.x - x : width * 0.58
        readonly property real targetLocalY: root.occlusionTargetRect.visible ? root.occlusionTargetRect.y - y : height * 0.24
        readonly property real targetCenterX: targetLocalX + (root.occlusionTargetRect.width / 2)
        readonly property real targetCenterY: targetLocalY + (root.occlusionTargetRect.height / 2)
        readonly property real targetDiameter: Math.max(root.occlusionTargetRect.width, root.occlusionTargetRect.height)
        width: Math.max(root.width * 0.34, root.cardScale * 0.44)
        x: root.occlusionTargetRect.visible
            ? root.clampRange(
                root.occlusionTargetRect.x - Math.max(root.occlusionTargetRect.width * 0.68, root.cardScale * 0.12),
                0,
                Math.max(0, root.width - width)
            )
            : root.width - width
        y: root.occlusionTargetRect.visible
            ? root.clampRange(
                root.occlusionTargetRect.y - Math.max(root.occlusionTargetRect.height * 0.48, root.cardScale * 0.08),
                0,
                Math.max(0, root.height - height)
            )
            : root.occlusionTargetRect.y
        height: root.occlusionTargetRect.visible
            ? Math.max(
                root.cardScale * 0.24,
                Math.min(
                    root.height * 0.56,
                    root.occlusionTargetRect.height + Math.max(root.occlusionTargetRect.height * 1.1, root.cardScale * 0.22)
                )
            )
            : root.occlusionTargetRect.height
        visible: root.orbOcclusionOpacity > 0.04 && root.orbOcclusionBands > 0
        clip: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.cloudUndersideTintColor, root.orbOcclusionOpacity * 0.18)
                }
                GradientStop {
                    position: 0.34
                    color: root.withAlpha(root.cloudWarmTintColor, root.orbOcclusionOpacity * 0.12)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        Item {
            id: orbMaskCluster

            objectName: "orbMaskClusterItem"
            property real driftOffset: 0
            readonly property real clusterWidth: Math.max(
                celestialOcclusionLayer.targetDiameter * (1.56 + (root.orbOcclusionOpacity * 0.28)),
                root.cardScale * 0.3
            )
            readonly property real clusterHeight: Math.max(
                root.occlusionTargetRect.height * (0.92 + (root.orbOcclusionOpacity * 0.18)),
                root.cardScale * 0.18
            )

            visible: root.orbMaskActive
            width: clusterWidth
            height: clusterHeight
            x: root.clampRange(
                celestialOcclusionLayer.targetCenterX - (width * (0.58 - (root.windDrift * 0.06))),
                -width * 0.08,
                Math.max(0, celestialOcclusionLayer.width - (width * 0.12))
            )
            y: root.clampRange(
                celestialOcclusionLayer.targetCenterY - (height * (0.42 + ((1 - root.cloudBreakFactor) * 0.08))),
                0,
                Math.max(0, celestialOcclusionLayer.height - height)
            )
            clip: true

            SequentialAnimation on driftOffset {
                loops: Animation.Infinite
                running: orbMaskCluster.visible

                NumberAnimation {
                    from: -root.occlusionShiftSpan * 0.22
                    to: root.occlusionShiftSpan * 0.28
                    duration: Math.round(3600 + ((1 - root.windStrength) * 1800))
                    easing.type: Easing.InOutSine
                }

                NumberAnimation {
                    from: root.occlusionShiftSpan * 0.28
                    to: -root.occlusionShiftSpan * 0.22
                    duration: Math.round(3400 + ((1 - root.windStrength) * 1600))
                    easing.type: Easing.InOutSine
                }
            }

            Item {
                width: parent.width
                height: parent.height
                x: orbMaskCluster.driftOffset

                Rectangle {
                    width: parent.width * 0.9
                    height: parent.height * 0.42
                    radius: height / 2
                    x: parent.width * 0.04
                    y: parent.height * 0.24
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudTopTintColor, root.orbOcclusionOpacity * 0.26)
                        }
                        GradientStop {
                            position: 0.36
                            color: root.withAlpha(root.cloudWarmTintColor, root.orbOcclusionOpacity * 0.66)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudUndersideTintColor, root.orbOcclusionOpacity * 0.72)
                        }
                    }
                }

                Rectangle {
                    width: parent.width * 0.34
                    height: parent.height * 0.58
                    radius: height / 2
                    x: parent.width * 0.08
                    y: parent.height * 0.08
                    color: root.withAlpha(root.cloudTopTintColor, root.orbOcclusionOpacity * 0.46)
                }

                Rectangle {
                    width: parent.width * 0.3
                    height: parent.height * 0.48
                    radius: height / 2
                    x: parent.width * 0.5
                    y: parent.height * 0.02
                    color: root.withAlpha(root.cloudWarmTintColor, root.orbOcclusionOpacity * 0.38)
                }

                Rectangle {
                    width: parent.width * 0.42
                    height: Math.max(2, parent.height * 0.14)
                    radius: height / 2
                    x: parent.width * 0.28
                    y: parent.height * 0.18
                    color: root.withAlpha(root.cloudTopTintColor, root.orbOcclusionOpacity * 0.2)
                }

                Rectangle {
                    width: parent.width * 0.46
                    height: parent.height * 0.18
                    radius: height / 2
                    x: parent.width * 0.18
                    y: parent.height * 0.46
                    color: root.withAlpha(root.cloudUndersideTintColor, root.orbOcclusionOpacity * 0.42)
                }
            }
        }

        Repeater {
            model: root.orbOcclusionBands

            delegate: Item {
                id: occlusionBand

                required property int index

                readonly property real bandWidth: celestialOcclusionLayer.width * (0.62 + (root.sampleUnit(index + 1, 31) * 0.3))
                readonly property real bandHeight: celestialOcclusionLayer.height * (0.12 + (root.sampleUnit(index + 1, 32) * 0.07))
                readonly property real bandOpacity: root.orbOcclusionOpacity * (0.28 + (root.sampleUnit(index + 1, 33) * 0.16))
                readonly property real startY: celestialOcclusionLayer.height * (0.04 + (root.sampleUnit(index + 1, 34) * 0.62))
                readonly property real durationMs: 3600 + Math.round((1 - root.motionBudget) * 900) + Math.round((1 - root.windStrength) * 700) + Math.round(root.sampleUnit(index + 1, 35) * 900)

                width: bandWidth
                height: bandHeight
                y: startY

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: celestialOcclusionLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0
                            ? -occlusionBand.width * 0.9
                            : celestialOcclusionLayer.width
                        to: root.cloudTravelDirection > 0
                            ? celestialOcclusionLayer.width
                            : -occlusionBand.width * 0.9
                        duration: occlusionBand.durationMs
                        easing.type: Easing.Linear
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: root.withAlpha(root.cloudTopTintColor, occlusionBand.bandOpacity * 0.54)
                        }
                        GradientStop {
                            position: 0.46
                            color: root.withAlpha(root.cloudWarmTintColor, occlusionBand.bandOpacity)
                        }
                        GradientStop {
                            position: 1
                            color: root.withAlpha(root.cloudUndersideTintColor, occlusionBand.bandOpacity * 0.92)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: heatShimmerLayer

        objectName: "heatShimmerLayerItem"
        anchors.fill: parent
        visible: root.showHeatShimmer

        Rectangle {
            width: root.width * 0.72
            height: root.height * (0.12 + (root.heatStrength * 0.06))
            radius: height / 2
            x: root.clampRange(root.lightSourceCenterX - (width / 2), -width * 0.08, root.width - (width * 0.92))
            y: root.height * 0.66
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.cloudGlowColor, 0)
                }
                GradientStop {
                    position: 0.5
                    color: root.withAlpha(
                        root.blendColors(root.cloudGlowColor, root.twilightWarmColor, root.heatStrength * 0.18),
                        root.heatStrength * 0.14
                    )
                }
                GradientStop {
                    position: 1
                    color: root.withAlpha(root.cloudGlowColor, 0)
                }
            }
        }

        Repeater {
            model: Math.max(3, Math.round((3 + (root.heatStrength * 5)) * root.detailBudget))

            delegate: Rectangle {
                required property int index

                readonly property real widthFactor: 0.16 + (root.sampleUnit(index + 61, 1) * 0.2)
                readonly property real baseX: root.clampRange(
                    root.lightSourceCenterX - ((root.width * widthFactor) / 2) + ((root.sampleUnit(index + 61, 2) - 0.5) * root.width * 0.16),
                    -root.width * 0.06,
                    root.width * 0.9
                )
                readonly property real baseY: root.height * (0.56 + (root.sampleUnit(index + 61, 3) * 0.22))
                readonly property real riseDistance: root.cardScale * (0.03 + (root.heatStrength * 0.05) + (root.sampleUnit(index + 61, 4) * 0.03))
                readonly property real driftDistance: (root.windDrift * root.width * 0.04) + ((root.sampleUnit(index + 61, 5) - 0.5) * root.width * 0.03)

                width: root.width * widthFactor
                height: Math.max(root.cardScale * 0.016, root.height * (0.014 + (root.sampleUnit(index + 61, 6) * 0.012)))
                radius: height / 2
                x: baseX
                y: baseY
                opacity: 0.18 + (root.heatStrength * 0.22)
                rotation: (root.windDrift * 5) + ((root.sampleUnit(index + 61, 7) - 0.5) * 6)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.cloudGlowColor, 0)
                    }
                    GradientStop {
                        position: 0.5
                        color: root.withAlpha(root.cloudGlowColor, 0.28 + (root.heatStrength * 0.18))
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.cloudGlowColor, 0)
                    }
                }

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: heatShimmerLayer.visible

                    NumberAnimation {
                        from: baseY
                        to: baseY - riseDistance
                        duration: 1100 + Math.round(root.sampleUnit(index + 61, 8) * 700) + Math.round((1 - root.motionBudget) * 500)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: baseY - riseDistance
                        to: baseY
                        duration: 1100 + Math.round(root.sampleUnit(index + 61, 9) * 700) + Math.round((1 - root.motionBudget) * 500)
                        easing.type: Easing.InOutSine
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: heatShimmerLayer.visible

                    NumberAnimation {
                        from: baseX - (driftDistance * 0.32)
                        to: baseX + driftDistance
                        duration: 1200 + Math.round(root.sampleUnit(index + 61, 10) * 700)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: baseX + driftDistance
                        to: baseX - (driftDistance * 0.32)
                        duration: 1200 + Math.round(root.sampleUnit(index + 61, 11) * 700)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Rectangle {
        id: skyFogVeil

        objectName: "skyFogVeilItem"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * (0.42 + (root.fogDepth * 0.24))
        visible: root.showFogSkyVeil
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.fogFarTintColor, root.fogOpacity * (0.44 + (root.fogDepth * 0.16)))
            }
            GradientStop {
                position: 0.62
                color: root.withAlpha(root.fogFarTintColor, root.fogOpacity * 0.3)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }

    Rectangle {
        id: clearingMistLayer

        objectName: "clearingMistLayerItem"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * (0.14 + (root.clearingStrength * 0.1))
        visible: root.showClearingMist
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.clearingMistColor, 0)
            }
            GradientStop {
                position: 0.46
                color: root.withAlpha(root.clearingMistColor, root.clearingStrength * 0.08)
            }
            GradientStop {
                position: 1
                color: root.withAlpha(root.clearingMistColor, root.clearingStrength * 0.18)
            }
        }
    }

    Item {
        id: farFogLayer

        objectName: "farFogLayerItem"
        anchors.fill: parent
        visible: root.showFog

        Repeater {
            model: root.farFogBandCount

            delegate: Rectangle {
                id: fogBand

                required property int index

                readonly property real bandOpacity: root.fogOpacity * (0.18 + (root.fogDepth * 0.16) + (root.sampleUnit(index + 7, 2) * 0.08))
                readonly property real bandY: (root.height * 0.18) + (index * root.height * 0.18)
                readonly property real horizontalShift: root.width * (0.06 + (Math.abs(root.windDrift) * 0.14) + (root.sampleUnit(index + 7, 3) * 0.08)) * (0.28 + (root.motionBudget * 0.72))

                width: root.width * 1.38
                height: root.height * (0.16 + (root.sampleUnit(index + 7, 4) * 0.08))
                radius: height / 2
                x: -root.width * 0.16
                y: bandY
                opacity: bandOpacity
                color: Qt.rgba(0, 0, 0, 0)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.fogColor, 0)
                    }
                    GradientStop {
                        position: 0.42
                        color: root.withAlpha(root.fogFarTintColor, fogBand.bandOpacity * 0.92)
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.fogFarTintColor, 0)
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: farFogLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0
                            ? -root.width * 0.22
                            : horizontalShift - (root.width * 0.22)
                        to: root.cloudTravelDirection > 0
                            ? horizontalShift - (root.width * 0.22)
                            : -root.width * 0.22
                        duration: 5400 + Math.round((1 - root.windStrength) * 1800) + (index * 900)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0
                            ? horizontalShift - (root.width * 0.22)
                            : -root.width * 0.22
                        to: root.cloudTravelDirection > 0
                            ? -root.width * 0.22
                            : horizontalShift - (root.width * 0.22)
                        duration: 5400 + Math.round((1 - root.windStrength) * 1800) + (index * 900)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Item {
        id: midFogLayer

        objectName: "midFogLayerItem"
        anchors.fill: parent
        visible: root.showFog && root.midFogBandCount > 0

        Repeater {
            model: root.midFogBandCount

            delegate: Rectangle {
                required property int index

                readonly property real bandOpacity: root.fogOpacity * (0.22 + (root.fogDepth * 0.18) + (root.sampleUnit(index + 12, 2) * 0.08))
                readonly property real bandY: root.height * (0.28 + (index * 0.14))
                readonly property real travelSpan: root.width * (0.1 + (root.windStrength * 0.16) + (root.sampleUnit(index + 12, 3) * 0.06)) * (0.28 + (root.motionBudget * 0.72))

                width: root.width * 1.42
                height: root.height * (0.18 + (root.sampleUnit(index + 12, 4) * 0.08))
                radius: height / 2
                y: bandY
                color: Qt.rgba(0, 0, 0, 0)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.fogFarTintColor, 0)
                    }
                    GradientStop {
                        position: 0.44
                        color: root.withAlpha(root.blendColors(root.fogFarTintColor, root.fogNearTintColor, 0.3), bandOpacity)
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.fogNearTintColor, 0)
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: midFogLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? -root.width * 0.18 : (travelSpan - (root.width * 0.18))
                        to: root.cloudTravelDirection > 0 ? (travelSpan - (root.width * 0.18)) : -root.width * 0.18
                        duration: 4200 + Math.round((1 - root.windStrength) * 1400) + (index * 500)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? (travelSpan - (root.width * 0.18)) : -root.width * 0.18
                        to: root.cloudTravelDirection > 0 ? -root.width * 0.18 : (travelSpan - (root.width * 0.18))
                        duration: 4200 + Math.round((1 - root.windStrength) * 1400) + (index * 500)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Rectangle {
        id: horizonFogSheet

        objectName: "horizonFogSheetItem"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * (0.18 + (root.fogDepth * 0.12))
        visible: root.showFog
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.withAlpha(root.fogColor, 0)
            }
            GradientStop {
                position: 0.5
                color: root.withAlpha(root.fogNearTintColor, root.fogOpacity * (0.28 + (root.fogDepth * 0.16)))
            }
            GradientStop {
                position: 1
                color: root.withAlpha(
                    root.blendColors(root.fogNearTintColor, root.twilightWarmColor, root.twilightActive ? root.twilightWarmth * 0.18 : 0),
                    root.fogOpacity * (0.56 + (root.fogDepth * 0.2))
                )
            }
        }
    }

    Item {
        id: nearFogLayer

        objectName: "nearFogLayerItem"
        anchors.fill: parent
        visible: root.showFog

        Repeater {
            model: root.nearFogBandCount

            delegate: Rectangle {
                required property int index

                readonly property real bandOpacity: root.fogOpacity * (0.24 + (root.fogDepth * 0.18) + (root.sampleUnit(index + 17, 2) * 0.08))
                readonly property real bandY: root.height * (0.42 + (index * 0.14))
                readonly property real travelSpan: root.width * (0.14 + (Math.abs(root.windDrift) * 0.12)) * (0.3 + (root.motionBudget * 0.7))

                width: root.width * 1.44
                height: root.height * (0.2 + (root.sampleUnit(index + 17, 3) * 0.1))
                radius: height / 2
                y: bandY
                color: Qt.rgba(0, 0, 0, 0)
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.fogNearTintColor, 0)
                    }
                    GradientStop {
                        position: 0.48
                        color: root.withAlpha(root.fogNearTintColor, bandOpacity)
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.fogNearTintColor, 0)
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: nearFogLayer.visible

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? -root.width * 0.2 : (travelSpan - (root.width * 0.2))
                        to: root.cloudTravelDirection > 0 ? (travelSpan - (root.width * 0.2)) : -root.width * 0.2
                        duration: 3000 + Math.round((1 - root.windStrength) * 1400) + (index * 600)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: root.cloudTravelDirection > 0 ? (travelSpan - (root.width * 0.2)) : -root.width * 0.2
                        to: root.cloudTravelDirection > 0 ? -root.width * 0.2 : (travelSpan - (root.width * 0.2))
                        duration: 3000 + Math.round((1 - root.windStrength) * 1400) + (index * 600)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Item {
        id: rainCurtainLayer

        objectName: "rainCurtainLayerItem"
        anchors.fill: parent
        visible: root.showRainCurtain

        property real driftOffset: 0

        SequentialAnimation on driftOffset {
            loops: Animation.Infinite
            running: rainCurtainLayer.visible

            NumberAnimation {
                from: -root.windShiftSpan * 0.42
                to: root.windShiftSpan * 0.58
                duration: 1700 + Math.round((1 - root.windStrength) * 600)
                easing.type: Easing.Linear
            }

            NumberAnimation {
                from: root.windShiftSpan * 0.58
                to: -root.windShiftSpan * 0.42
                duration: 1700 + Math.round((1 - root.windStrength) * 600)
                easing.type: Easing.Linear
            }
        }

        Repeater {
            model: effectiveRainBand === "downpour" ? 7 : 6

            delegate: Rectangle {
                required property int index

                width: root.width * 1.5
                height: root.height * ((root.effectiveRainBand === "downpour" ? 0.2 : 0.18) + (index * 0.05))
                radius: height / 2
                x: -root.width * 0.24 + rainCurtainLayer.driftOffset
                y: root.height * (0.1 + (index * 0.125))
                rotation: root.rainAngleDegrees * 0.42
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: root.withAlpha(root.precipitationColor, 0)
                    }
                    GradientStop {
                        position: 0.42
                        color: root.withAlpha(
                            root.blendColors(root.precipitationColor, root.cloudShadowColor, 0.5),
                            (root.effectiveRainBand === "downpour" ? 0.44 : 0.4) + (root.effectiveRainDensity * 0.3)
                        )
                    }
                    GradientStop {
                        position: 0.68
                        color: root.withAlpha(
                            root.blendColors(root.precipitationColor, root.cloudShadowColor, 0.32),
                            (root.effectiveRainBand === "downpour" ? 0.34 : 0.28) + (root.effectiveRainDensity * 0.2)
                        )
                    }
                    GradientStop {
                        position: 0.84
                        color: root.withAlpha(
                            root.blendColors(root.precipitationColor, root.cloudShadowColor, 0.18),
                            (root.effectiveRainBand === "downpour" ? 0.16 : 0.12) + (root.effectiveRainDensity * 0.12)
                        )
                    }
                    GradientStop {
                        position: 1
                        color: root.withAlpha(root.precipitationColor, 0)
                    }
                }
            }
        }
    }

    Item {
        id: rainLayer

        objectName: "rainLayerItem"
        anchors.fill: parent
        visible: root.showRain

        Repeater {
            model: root.rainParticleCount

            delegate: Rectangle {
                required property int index

                readonly property real horizontalUnit: root.sampleUnit(index + 1, 11)
                readonly property real verticalUnit: root.sampleUnit(index + 1, 12)
                readonly property real streakOpacity: (root.effectiveRainBand === "drizzle" ? 0.56 : (root.effectiveRainBand === "downpour" ? 0.34 : 0.24))
                    + (root.sampleUnit(index + 1, 13) * (root.effectiveRainBand === "drizzle" ? 0.36 : 0.22))
                    + (root.effectiveStorminess * 0.12)
                readonly property real durationScale: (root.effectiveRainBand === "drizzle" ? 1.18 : (root.effectiveRainBand === "downpour" ? 0.46 : 0.72)) + (root.sampleUnit(index + 1, 14) * 0.34)
                readonly property real lengthFactor: root.effectiveRainBand === "drizzle" ? 1.34 : (root.effectiveRainBand === "downpour" ? 1.78 : 1.18)
                readonly property real startX: (horizontalUnit * (root.width + (root.height * 0.44))) - (root.height * 0.22)
                readonly property real windOffset: root.windDrift * root.height * (0.16 + (root.windStrength * 0.26)) * (0.26 + (root.motionBudget * 0.74))
                readonly property int fallDuration: Math.round((820 - (root.windStrength * 220) - (root.effectiveStorminess * 140)) * durationScale)

                width: Math.max(1, Math.round(root.cardScale * (root.effectiveRainBand === "downpour" ? 0.013 : (root.effectiveRainBand === "drizzle" ? 0.01 : 0.008))))
                height: Math.max(root.cardScale * 0.1, root.height * (0.06 + (root.sampleUnit(index + 1, 15) * 0.06)) * lengthFactor)
                radius: width / 2
                x: startX
                rotation: root.rainAngleDegrees + (root.sampleUnit(index + 1, 16) * (root.effectiveRainBand === "drizzle" ? 4 : 8))
                color: root.withAlpha(root.precipitationColor, streakOpacity)

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: rainLayer.visible

                    NumberAnimation {
                        from: -height - (verticalUnit * root.height)
                        to: root.height + height
                        duration: fallDuration
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: rainLayer.visible

                    NumberAnimation {
                        from: startX - (windOffset * 0.3)
                        to: startX + windOffset
                        duration: fallDuration
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    Item {
        id: snowLayer

        objectName: "snowLayerItem"
        anchors.fill: parent
        visible: root.showSnow

        Repeater {
            model: root.snowParticleCount

            delegate: Rectangle {
                required property int index

                readonly property real horizontalUnit: root.sampleUnit(index + 1, 21)
                readonly property real driftAmplitude: root.width * ((root.snowBand === "flurries" ? 0.028 : (root.snowBand === "heavy" ? 0.062 : 0.04)) + (root.sampleUnit(index + 1, 22) * 0.03) + (root.windStrength * 0.04)) * (0.28 + (root.motionBudget * 0.72))
                readonly property real flakeOpacity: (root.snowBand === "heavy" ? 0.62 : (root.snowBand === "flurries" ? 0.32 : 0.46)) + (root.sampleUnit(index + 1, 23) * 0.18)
                readonly property real sizeFactor: (root.snowBand === "flurries" ? 0.006 : (root.snowBand === "heavy" ? 0.02 : 0.013)) + (root.sampleUnit(index + 1, 24) * 0.014)
                readonly property real durationScale: (root.snowBand === "flurries" ? 1.28 : (root.snowBand === "heavy" ? 0.72 : 0.92)) + (root.sampleUnit(index + 1, 25) * 0.38)
                readonly property real startX: horizontalUnit * root.width
                readonly property real driftBias: root.windDrift * root.width * (0.05 + (root.windStrength * 0.12)) * (0.28 + (root.motionBudget * 0.72))
                readonly property int fallDuration: Math.round((2620 - (root.windStrength * 620)) * durationScale)

                width: Math.max(2, Math.round(root.cardScale * sizeFactor))
                height: width
                radius: width / 2
                color: root.withAlpha(root.snowColor, flakeOpacity)

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: snowLayer.visible

                    NumberAnimation {
                        from: -height - (root.sampleUnit(index + 1, 26) * root.height * 0.8)
                        to: root.height + height
                        duration: fallDuration
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: snowLayer.visible

                    NumberAnimation {
                        from: startX - driftAmplitude + (driftBias * 0.2)
                        to: startX + driftAmplitude + driftBias
                        duration: 1800 + Math.round(root.sampleUnit(index + 1, 27) * 900) - Math.round(root.windStrength * 320)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: startX + driftAmplitude + driftBias
                        to: startX - driftAmplitude + (driftBias * 0.2)
                        duration: 1800 + Math.round(root.sampleUnit(index + 1, 28) * 900) - Math.round(root.windStrength * 320)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Item {
        id: snowNearFieldLayer

        objectName: "snowNearFieldLayerItem"
        anchors.fill: parent
        visible: root.showSnowNearField

        Repeater {
            model: Math.max(6, Math.round((root.snowBand === "heavy" ? 18 : 10) * root.detailBudget))

            delegate: Rectangle {
                required property int index

                readonly property real horizontalUnit: root.sampleUnit(index + 31, 21)
                readonly property real startX: horizontalUnit * root.width
                readonly property real swayAmplitude: root.width * (0.04 + (root.windStrength * 0.08) + (root.sampleUnit(index + 31, 22) * 0.04)) * (0.28 + (root.motionBudget * 0.72))
                readonly property real driftBias: root.windDrift * root.width * (0.08 + (root.windStrength * 0.1)) * (0.28 + (root.motionBudget * 0.72))
                readonly property int fallDuration: Math.round((2000 - (root.windStrength * 500)) * (0.72 + (root.sampleUnit(index + 31, 23) * 0.34)))

                width: Math.max(3, Math.round(root.cardScale * ((root.snowBand === "heavy" ? 0.022 : 0.015) + (root.sampleUnit(index + 31, 24) * 0.012))))
                height: width
                radius: width / 2
                color: root.withAlpha(root.snowColor, (root.snowBand === "heavy" ? 0.58 : 0.42) + (root.sampleUnit(index + 31, 25) * 0.16))

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    running: snowNearFieldLayer.visible

                    NumberAnimation {
                        from: -height - (root.sampleUnit(index + 31, 26) * root.height * 0.7)
                        to: root.height + height
                        duration: fallDuration
                        easing.type: Easing.Linear
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    running: snowNearFieldLayer.visible

                    NumberAnimation {
                        from: startX - swayAmplitude
                        to: startX + swayAmplitude + driftBias
                        duration: 1500 + Math.round(root.sampleUnit(index + 31, 27) * 700)
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: startX + swayAmplitude + driftBias
                        to: startX - swayAmplitude
                        duration: 1500 + Math.round(root.sampleUnit(index + 31, 28) * 700)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    Item {
        id: lightningLayer

        objectName: "lightningLayerItem"
        anchors.fill: parent
        visible: root.lightningEnabled
        property real flashOpacity: 0
        property real afterglowOpacity: 0
        property real boltOpacity: 0
        property real strikeAnchor: root.lightningFlashSide
        property real strikeHeightFactor: 0.16
        property real strikeTilt: 0
        property real pulsePeak: 0.24
        property real secondaryPulsePeak: 0.1

        Rectangle {
            anchors.fill: parent
            color: root.lightningColor
            opacity: lightningLayer.flashOpacity * (0.58 + (root.storminess * 0.14))
        }

        Rectangle {
            id: lightningDirectionalFlash

            objectName: "lightningDirectionalFlashItem"
            width: parent.width * 0.82
            height: parent.height
            x: (lightningLayer.strikeAnchor * parent.width) - (width * 0.58)
            y: 0
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: root.withAlpha(root.lightningColor, 0)
                }
                GradientStop {
                    position: 0.26
                    color: root.withAlpha(root.lightningColor, lightningLayer.flashOpacity * (0.06 + (root.storminess * 0.08)))
                }
                GradientStop {
                    position: 0.62
                    color: root.withAlpha(
                        root.blendColors(root.lightningColor, root.cloudGlowColor, 0.18),
                        lightningLayer.flashOpacity * (0.18 + (root.storminess * 0.16))
                    )
                }
                GradientStop {
                    position: 1
                    color: root.withAlpha(root.lightningColor, 0)
                }
            }
        }

        Rectangle {
            width: parent.width * 0.96
            height: parent.height * 0.46
            radius: height / 2
            x: (lightningLayer.strikeAnchor * parent.width) - (width / 2)
            y: parent.height * 0.02
            color: root.withAlpha(root.lightningColor, lightningLayer.afterglowOpacity * 0.18)
        }

        Item {
            id: lightningBolt

            objectName: "lightningBoltItem"
            visible: root.detailBudget > 0.34 && lightningLayer.boltOpacity > 0.01
            width: parent.width * 0.28
            height: parent.height * 0.62
            x: root.clampRange((lightningLayer.strikeAnchor * parent.width) - (width * 0.46), 0, Math.max(0, parent.width - width))
            y: parent.height * lightningLayer.strikeHeightFactor
            opacity: lightningLayer.boltOpacity

            readonly property real boltWidth: Math.max(2, root.cardScale * 0.026)
            readonly property color boltColor: root.withAlpha(root.blendColors(root.lightningColor, root.cloudLiningColor, 0.12), 0.96)

            Rectangle {
                width: lightningBolt.boltWidth
                height: parent.height * 0.24
                radius: width / 2
                x: parent.width * 0.48
                y: 0
                rotation: lightningLayer.strikeTilt
                color: lightningBolt.boltColor
            }

            Rectangle {
                width: lightningBolt.boltWidth
                height: parent.height * 0.18
                radius: width / 2
                x: parent.width * 0.38
                y: parent.height * 0.18
                rotation: lightningLayer.strikeTilt - (root.cloudTravelDirection * 18)
                color: lightningBolt.boltColor
            }

            Rectangle {
                width: lightningBolt.boltWidth
                height: parent.height * 0.16
                radius: width / 2
                x: parent.width * 0.44
                y: parent.height * 0.34
                rotation: lightningLayer.strikeTilt + (root.cloudTravelDirection * 12)
                color: lightningBolt.boltColor
            }

            Rectangle {
                width: Math.max(1, lightningBolt.boltWidth * 0.72)
                height: parent.height * 0.1
                radius: width / 2
                x: parent.width * 0.32
                y: parent.height * 0.26
                rotation: lightningLayer.strikeTilt - (root.cloudTravelDirection * 34)
                color: lightningBolt.boltColor
            }

            Rectangle {
                width: Math.max(1, lightningBolt.boltWidth * 0.66)
                height: parent.height * 0.08
                radius: width / 2
                x: parent.width * 0.5
                y: parent.height * 0.42
                rotation: lightningLayer.strikeTilt + (root.cloudTravelDirection * 28)
                color: lightningBolt.boltColor
            }
        }
    }

    Timer {
        id: lightningTimer

        interval: 2200
        repeat: true
        running: root.lightningEnabled

        onTriggered: {
            interval = Math.max(
                520,
                Math.round((860 + (Math.random() * 1700)) * root.lightningCadence * (0.96 - (root.windStrength * 0.12)))
            );
            lightningLayer.flashOpacity = 0;
            lightningLayer.afterglowOpacity = 0;
            lightningLayer.boltOpacity = 0;
            lightningLayer.strikeAnchor = root.clampRange(root.lightningFlashSide + ((Math.random() - 0.5) * 0.18), 0.14, 0.86);
            lightningLayer.strikeHeightFactor = 0.1 + (Math.random() * 0.16);
            lightningLayer.strikeTilt = ((Math.random() - 0.5) * 22) + (root.cloudTravelDirection * 8);
            lightningLayer.pulsePeak = 0.18 + (root.storminess * 0.16) + (Math.random() * 0.08);
            lightningLayer.secondaryPulsePeak = lightningLayer.pulsePeak * (0.34 + (Math.random() * 0.18));
            lightningPulse.restart();
        }
    }

    SequentialAnimation {
        id: lightningPulse

        ParallelAnimation {
            NumberAnimation {
                target: lightningLayer
                property: "boltOpacity"
                to: 0.92
                duration: 36
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: lightningLayer
                property: "flashOpacity"
                to: lightningLayer.pulsePeak
                duration: 64
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: lightningLayer
                property: "afterglowOpacity"
                to: lightningLayer.pulsePeak * 0.28
                duration: 76
                easing.type: Easing.OutQuad
            }
        }

        PauseAnimation {
            duration: 24
        }

        ParallelAnimation {
            NumberAnimation {
                target: lightningLayer
                property: "flashOpacity"
                to: lightningLayer.secondaryPulsePeak
                duration: 88
                easing.type: Easing.InOutQuad
            }

            NumberAnimation {
                target: lightningLayer
                property: "boltOpacity"
                to: 0.26
                duration: 84
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                target: lightningLayer
                property: "afterglowOpacity"
                to: lightningLayer.pulsePeak * 0.48
                duration: 92
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: lightningLayer
                property: "flashOpacity"
                to: 0
                duration: 170
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                target: lightningLayer
                property: "boltOpacity"
                to: 0
                duration: 116
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                target: lightningLayer
                property: "afterglowOpacity"
                to: 0
                duration: 240
                easing.type: Easing.InQuad
            }
        }
    }
}
