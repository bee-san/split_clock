import QtQuick 2.15
import QtTest 1.2

import "../contents/ui"

TestCase {
    id: testCase

    name: "WeatherOverlay"
    when: windowShown

    function cloudyState() {
        return {
            "kind": "cloudy",
            "cloudOpacity": 0.72,
            "cloudBandCount": 4,
            "cloudFamily": "stratus",
            "cloudBreakFactor": 0.24,
            "cloudShadowStrength": 0.12,
            "orbOcclusionOpacity": 0.44,
            "orbOcclusionBands": 3
        };
    }

    function wispyCloudState() {
        return {
            "kind": "cloudy",
            "cloudOpacity": 0.32,
            "cloudBandCount": 2,
            "cloudFamily": "wispy",
            "cloudBreakFactor": 0.84,
            "orbOcclusionOpacity": 0.2,
            "orbOcclusionBands": 2
        };
    }

    function cumulusCloudState() {
        return {
            "kind": "cloudy",
            "cloudOpacity": 0.54,
            "cloudBandCount": 3,
            "cloudFamily": "cumulus",
            "cloudBreakFactor": 0.48,
            "orbOcclusionOpacity": 0.32,
            "orbOcclusionBands": 3
        };
    }

    function clearSummerState() {
        return {
            "kind": "clear",
            "cloudOpacity": 0.04,
            "cloudBandCount": 0,
            "cloudFamily": "none",
            "cloudBreakFactor": 1,
            "windDrift": 0.14,
            "motionStrength": 0.32
        };
    }

    function downpourState() {
        return {
            "kind": "rain",
            "cloudOpacity": 0.84,
            "cloudBandCount": 4,
            "cloudFamily": "stratus",
            "cloudBreakFactor": 0.12,
            "orbOcclusionOpacity": 0.56,
            "orbOcclusionBands": 4,
            "rainDensity": 0.9,
            "rainBand": "downpour",
            "windDrift": 0.72,
            "motionStrength": 0.86,
            "storminess": 0.38
        };
    }

    function heavySnowState() {
        return {
            "kind": "snow",
            "cloudOpacity": 0.8,
            "cloudBandCount": 4,
            "cloudFamily": "stratus",
            "cloudBreakFactor": 0.18,
            "orbOcclusionOpacity": 0.42,
            "orbOcclusionBands": 3,
            "snowDensity": 0.82,
            "snowBand": "heavy",
            "windDrift": -0.42,
            "motionStrength": 0.54
        };
    }

    function fogState() {
        return {
            "kind": "fog",
            "cloudOpacity": 0.4,
            "cloudBandCount": 2,
            "cloudFamily": "veil",
            "cloudBreakFactor": 0.16,
            "fogOpacity": 0.72,
            "fogDepth": 0.88,
            "windDrift": 0.3,
            "motionStrength": 0.44
        };
    }

    function humidClearState() {
        return {
            "kind": "clear",
            "cloudOpacity": 0.08,
            "cloudBandCount": 1,
            "cloudFamily": "wispy",
            "cloudBreakFactor": 0.92,
            "humidity": 0.86,
            "humidityHaze": 0.42,
            "humidityBloom": 0.34
        };
    }

    function postRainClearingState() {
        return {
            "kind": "clear",
            "cloudOpacity": 0.26,
            "cloudBandCount": 3,
            "cloudFamily": "cumulus",
            "cloudBreakFactor": 0.68,
            "humidity": 0.82,
            "humidityHaze": 0.48,
            "humidityBloom": 0.28,
            "cloudShadowStrength": 0.34,
            "clearingStrength": 0.72,
            "fogOpacity": 0.08,
            "fogDepth": 0.24
        };
    }

    function windyCloudState() {
        return {
            "kind": "cloudy",
            "cloudOpacity": 0.58,
            "cloudBandCount": 3,
            "cloudFamily": "cumulus",
            "cloudBreakFactor": 0.42,
            "windDrift": 0.88,
            "motionStrength": 0.9
        };
    }

    function stormShelfState() {
        return {
            "kind": "thunderstorm",
            "cloudOpacity": 0.92,
            "cloudBandCount": 5,
            "cloudFamily": "shelf",
            "cloudBreakFactor": 0.04,
            "orbOcclusionOpacity": 0.66,
            "orbOcclusionBands": 5,
            "rainDensity": 0.86,
            "rainBand": "downpour",
            "storminess": 0.84,
            "windDrift": 0.62,
            "motionStrength": 0.92,
            "lightningCadence": 0.44,
            "lightning": true
        };
    }

    function colorDistance(firstColor, secondColor) {
        return Math.abs(firstColor.r - secondColor.r)
            + Math.abs(firstColor.g - secondColor.g)
            + Math.abs(firstColor.b - secondColor.b);
    }

    function findObject(parent, objectName) {
        if (!parent) {
            return null;
        }

        if (parent.objectName === objectName) {
            return parent;
        }

        const childList = parent.children || [];

        for (let index = 0; index < childList.length; index += 1) {
            const match = findObject(childList[index], objectName);

            if (match) {
                return match;
            }
        }

        return null;
    }

    Component {
        id: overlayComponent

        WeatherOverlay {
            width: 220
            height: 120
        }
    }

    function test_occlusionLayerTracksLowerSunPosition() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": cloudyState(),
            "sunRect": {
                "visible": true,
                "x": 162,
                "y": 66,
                "width": 30,
                "height": 30
            }
        });
        const layer = findObject(overlay, "celestialOcclusionLayerItem");
        const sunCenterY = overlay.sunRect.y + (overlay.sunRect.height / 2);

        verify(overlay !== null);
        wait(0);
        verify(layer !== null);
        compare(overlay.showClouds, true);
        compare(overlay.occlusionTargetRect.visible, true);
        verify(layer.height > 0);
        verify(sunCenterY >= layer.y);
        verify(sunCenterY <= layer.y + layer.height);
        verify(layer.y > 20);
    }

    function test_orbMaskClusterExpandsAcrossOccludedOrb() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": cloudyState(),
            "sunRect": {
                "visible": true,
                "x": 160,
                "y": 42,
                "width": 28,
                "height": 28
            }
        });
        const cluster = findObject(overlay, "orbMaskClusterItem");

        verify(overlay !== null);
        wait(0);
        verify(cluster !== null);
        compare(overlay.orbMaskActive, true);
        verify(cluster.width > overlay.sunRect.width);
        verify(cluster.height > overlay.sunRect.height * 0.6);
    }

    function test_downpourEnablesRainCurtainAndSteeperSlant() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": downpourState()
        });

        verify(overlay !== null);
        wait(0);
        compare(overlay.showRainCurtain, true);
        verify(overlay.rainParticleCount >= 46);
        verify(Math.abs(overlay.rainAngleDegrees) > 18);
    }

    function test_heavySnowEnablesNearFieldLayer() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": heavySnowState()
        });

        verify(overlay !== null);
        wait(0);
        compare(overlay.showSnowNearField, true);
        compare(overlay.snowBand, "heavy");
        verify(overlay.snowParticleCount >= 32);
    }

    function test_twilightCloudColorsShiftWarmAndCool() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": cloudyState(),
            "twilightActive": true,
            "twilightWarmth": 0.78,
            "twilightCoolness": 0.56,
            "twilightWarmColor": Qt.rgba(1, 0.72, 0.5, 1),
            "twilightCoolColor": Qt.rgba(0.5, 0.66, 0.92, 1)
        });

        verify(overlay !== null);
        wait(0);
        verify(colorDistance(overlay.cloudWarmTintColor, overlay.cloudColor) > 0.08);
        verify(colorDistance(overlay.cloudTopTintColor, overlay.cloudHighlightColor) > 0.04);
    }

    function test_deepFogAddsMidAndSkyLayers() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": fogState()
        });
        const midFogLayer = findObject(overlay, "midFogLayerItem");
        const skyFogVeil = findObject(overlay, "skyFogVeilItem");

        verify(overlay !== null);
        wait(0);
        verify(midFogLayer !== null);
        verify(skyFogVeil !== null);
        verify(overlay.midFogBandCount >= 2);
        compare(overlay.showFogSkyVeil, true);
    }

    function test_wispyCloudsEnableHighCloudLayer() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": wispyCloudState()
        });
        const highCloudLayer = findObject(overlay, "highCloudLayerItem");
        const wispyTrail = findObject(overlay, "wispyTrailShapeItem");

        verify(overlay !== null);
        wait(0);
        verify(highCloudLayer !== null);
        compare(overlay.showHighCloudWisps, true);
        compare(overlay.showWispyTrails, true);
        verify(wispyTrail !== null);
    }

    function test_cloudShadowsAppearInBrokenSunlitClouds() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": postRainClearingState(),
            "sunRect": {
                "visible": true,
                "x": 170,
                "y": 24,
                "width": 26,
                "height": 26
            }
        });
        const shadowLayer = findObject(overlay, "cloudShadowLayerItem");

        verify(overlay !== null);
        wait(0);
        verify(shadowLayer !== null);
        compare(overlay.showCloudShadows, true);
        verify(overlay.cloudShadowBandCount >= 2);
    }

    function test_humidityGlowWrapsVisibleLightSource() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": humidClearState(),
            "sunRect": {
                "visible": true,
                "x": 168,
                "y": 22,
                "width": 28,
                "height": 28
            }
        });
        const humidityLayer = findObject(overlay, "humidityGlowLayerItem");

        verify(overlay !== null);
        wait(0);
        verify(humidityLayer !== null);
        compare(overlay.showHumidityGlow, true);
        verify(overlay.humidityBloom > 0.2);
    }

    function test_postRainClearingAddsLowMistBand() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": postRainClearingState(),
            "sunRect": {
                "visible": true,
                "x": 166,
                "y": 20,
                "width": 30,
                "height": 30
            }
        });
        const clearingMist = findObject(overlay, "clearingMistLayerItem");

        verify(overlay !== null);
        wait(0);
        verify(clearingMist !== null);
        compare(overlay.showClearingMist, true);
        verify(overlay.clearingStrength > 0.6);
    }

    function test_strongWindEnablesWindLayer() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": windyCloudState()
        });
        const windLayer = findObject(overlay, "windLayerItem");

        verify(overlay !== null);
        wait(0);
        verify(windLayer !== null);
        compare(overlay.showWindStreaks, true);
        verify(overlay.windStrength > 0.7);
        verify(overlay.windStreakCount >= 5);
    }

    function test_cumulusFamilyBuildsPuffierSilhouettes() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": cumulusCloudState()
        });
        const cumulusShape = findObject(overlay, "cumulusPuffShapeItem");

        verify(overlay !== null);
        wait(0);
        compare(overlay.showCumulusPuffs, true);
        verify(cumulusShape !== null);
    }

    function test_stratusFamilyBuildsLayeredSilhouettes() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": cloudyState()
        });
        const stratusShape = findObject(overlay, "stratusLayerShapeItem");

        verify(overlay !== null);
        wait(0);
        compare(overlay.showLayeredStratus, true);
        verify(stratusShape !== null);
    }

    function test_stormShelfStateEnablesShelfLayer() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": stormShelfState()
        });
        const shelfLayer = findObject(overlay, "stormShelfLayerItem");
        const shelfUndercut = findObject(overlay, "shelfUndercutShapeItem");

        verify(overlay !== null);
        wait(0);
        verify(shelfLayer !== null);
        compare(overlay.showStormShelf, true);
        compare(overlay.showShelfUndercut, true);
        verify(shelfUndercut !== null);
        verify(overlay.lightningCadence < 0.5);
    }

    function test_hotClearDayEnablesHeatShimmer() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": clearSummerState(),
            "summerStrength": 0.92,
            "sunRect": {
                "visible": true,
                "x": 154,
                "y": 28,
                "width": 30,
                "height": 30
            }
        });
        const shimmerLayer = findObject(overlay, "heatShimmerLayerItem");

        verify(overlay !== null);
        wait(0);
        verify(shimmerLayer !== null);
        compare(overlay.showHeatShimmer, true);
        verify(overlay.heatStrength > 0.5);
    }

    function test_cloudLightingRespondsToActiveSun() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": cloudyState(),
            "orbLightColor": Qt.rgba(1, 0.9, 0.72, 1),
            "sunRect": {
                "visible": true,
                "x": 172,
                "y": 26,
                "width": 26,
                "height": 26
            }
        });

        verify(overlay !== null);
        wait(0);
        compare(overlay.lightSourceIsSun, true);
        verify(overlay.orbLightStrength > 0.4);
        verify(colorDistance(overlay.cloudLiningColor, overlay.cloudHighlightColor) > 0.03);
    }

    function test_stormLightningExposesDirectionalFlashAssets() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": stormShelfState()
        });
        const directionalFlash = findObject(overlay, "lightningDirectionalFlashItem");
        const bolt = findObject(overlay, "lightningBoltItem");

        verify(overlay !== null);
        wait(0);
        verify(directionalFlash !== null);
        verify(bolt !== null);
        verify(overlay.lightningFlashSide > 0.5);
    }

    function test_smallCardsReduceDetailBudget() {
        const overlay = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": stormShelfState(),
            "width": 120,
            "height": 72
        });

        verify(overlay !== null);
        wait(0);
        verify(overlay.detailBudget < 0.7);
        verify(overlay.rainParticleCount < 60);
    }

    function test_reducedMotionShrinksWindTravel() {
        const fullMotion = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": downpourState()
        });
        const reducedMotion = createTemporaryObject(overlayComponent, testCase, {
            "sceneState": downpourState(),
            "reducedMotion": true
        });

        verify(fullMotion !== null);
        verify(reducedMotion !== null);
        wait(0);
        verify(reducedMotion.motionBudget < fullMotion.motionBudget);
        verify(reducedMotion.windShiftSpan < fullMotion.windShiftSpan);
        verify(Math.abs(reducedMotion.rainAngleDegrees) < Math.abs(fullMotion.rainAngleDegrees));
    }
}
