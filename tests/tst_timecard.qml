import QtQuick 2.15
import QtTest 1.2

import "../contents/ui"

TestCase {
    id: testCase

    name: "TimeCard"
    when: windowShown

    property var clockParts: parts(2026, 4, 8, 7, 0, 0)
    property string clockOffset: "+09:00"

    function parts(year, month, day, hour, minute, second) {
        return {
            "year": year,
            "month": month,
            "day": day,
            "hour": hour,
            "minute": minute || 0,
            "second": second || 0
        };
    }

    function createCard(zoneId, entry, state, offset, width, height, weatherState) {
        clockParts = state;
        clockOffset = offset;

        const properties = {
            "timeZoneId": zoneId,
            "entry": entry,
            "width": width || 220,
            "height": height || 120
        };

        if (weatherState !== undefined) {
            properties.weatherStateOverride = weatherState;
        } else if (zoneId !== "Local") {
            properties.weatherStateOverride = clearWeatherState();
        }

        const card = createTemporaryObject(timeCardComponent, testCase, properties);

        verify(card !== null);
        wait(0);
        return card;
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

    function centerDistance(firstItem, secondItem) {
        const firstCenterX = firstItem.x + (firstItem.width / 2);
        const firstCenterY = firstItem.y + (firstItem.height / 2);
        const secondCenterX = secondItem.x + (secondItem.width / 2);
        const secondCenterY = secondItem.y + (secondItem.height / 2);
        const dx = secondCenterX - firstCenterX;
        const dy = secondCenterY - firstCenterY;

        return Math.sqrt((dx * dx) + (dy * dy));
    }

    function colorDistance(firstColor, secondColor) {
        return Math.abs(firstColor.r - secondColor.r)
            + Math.abs(firstColor.g - secondColor.g)
            + Math.abs(firstColor.b - secondColor.b);
    }

    function clearWeatherState() {
        return {
            "available": true,
            "status": "ready",
            "kind": "clear",
            "cloudOpacity": 0.04,
            "starVisibilityFactor": 1,
            "sunGlowFactor": 1,
            "moonGlowFactor": 1
        };
    }

    function rainWeatherState() {
        return {
            "available": true,
            "status": "ready",
            "kind": "rain",
            "cloudOpacity": 0.82,
            "rainDensity": 0.78,
            "starVisibilityFactor": 0,
            "sunGlowFactor": 0.44,
            "moonGlowFactor": 0.64,
            "skyDimming": 0.22,
            "contrastSoftening": 0.12
        };
    }

    function snowWeatherState() {
        return {
            "available": true,
            "status": "ready",
            "kind": "snow",
            "cloudOpacity": 0.74,
            "snowDensity": 0.72,
            "coolTint": 0.52,
            "starVisibilityFactor": 0.12,
            "sunGlowFactor": 0.58,
            "moonGlowFactor": 0.74,
            "skyDimming": 0.14,
            "contrastSoftening": 0.16
        };
    }

    function cloudyWeatherState() {
        return {
            "available": true,
            "status": "ready",
            "kind": "cloudy",
            "cloudOpacity": 0.64,
            "cloudBandCount": 4,
            "cloudBreakFactor": 0.32,
            "sunGlowFactor": 0.56,
            "moonGlowFactor": 0.66,
            "skyDimming": 0.16,
            "contrastSoftening": 0.1
        };
    }

    function stormWeatherState() {
        return {
            "available": true,
            "status": "ready",
            "kind": "thunderstorm",
            "cloudOpacity": 0.9,
            "rainDensity": 0.84,
            "storminess": 0.88,
            "lightning": true,
            "starVisibilityFactor": 0,
            "sunGlowFactor": 0.3,
            "moonGlowFactor": 0.48,
            "skyDimming": 0.3,
            "contrastSoftening": 0.14
        };
    }

    Component {
        id: fixedClockComponent

        Item {
            visible: false
            property var dateTime: testCase.clockParts
            property string timeZoneOffset: testCase.clockOffset
        }
    }

    Component {
        id: timeCardComponent

        TimeCard {
            clockComponentOverride: fixedClockComponent
        }
    }

    function test_remoteBodiesStayInLaneAtSmallSize() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 7, 0, 0),
            "+09:00",
            176,
            94
        );
        const lane = findObject(card, "orbLaneItem");
        const textColumn = findObject(card, "textColumnItem");
        const sun = findObject(card, "sunBodyItem");
        const moon = findObject(card, "moonBodyItem");

        verify(lane !== null);
        verify(textColumn !== null);
        verify(card.phasePalette.sunBody.visible);
        verify(card.phasePalette.moonBody.visible);
        compare(card.phasePalette.allowBodyOverlap, false);
        verify(sun.width > moon.width);
        verify(lane.x >= textColumn.x + textColumn.width);
        verify(sun.x >= 0 && sun.y >= 0);
        verify(moon.x >= 0 && moon.y >= 0);
        verify(sun.x + sun.width <= lane.width + 0.5);
        verify(moon.x + moon.width <= lane.width + 0.5);
        verify(sun.y + sun.height <= lane.height + 0.5);
        verify(moon.y + moon.height <= lane.height + 0.5);
        verify(centerDistance(sun, moon) + 0.25 >= (sun.width + moon.width) / 2);
    }

    function test_localNightUsesSimplifiedBodyPath() {
        const card = createCard(
            "Local",
            {
                "city": "Local",
                "label": "Local",
                "latitude": null,
                "longitude": null
            },
            parts(2026, 4, 12, 22, 0, 0),
            "",
            220,
            120
        );
        const sun = findObject(card, "sunBodyItem");
        const moon = findObject(card, "moonBodyItem");

        verify(card.phasePalette.usesSimplifiedCelestial);
        compare(card.phasePalette.moonBody.isSimplified, true);
        compare(card.phasePalette.sunBody.visible, false);
        compare(card.phasePalette.moonBody.visible, true);
    }

    function test_visualRefreshCounterUpdatesMoonState() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 7, 0, 0),
            "+09:00",
            220,
            120
        );
        const previousX = card.phasePalette.moonBody.x;
        const previousY = card.phasePalette.moonBody.y;
        const previousTimeText = card.timeText;

        clockParts.minute = 30;
        wait(0);
        compare(card.phasePalette.moonBody.x, previousX);
        compare(card.timeText, previousTimeText);

        card.visualRefreshCounter += 1;
        wait(0);

        verify(Math.abs(card.phasePalette.moonBody.x - previousX) > 0.0001
            || Math.abs(card.phasePalette.moonBody.y - previousY) > 0.0001);
        compare(card.timeText, "07:30");
    }

    function test_cardResizesOffscreenWithoutClippingBodies() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 1, 0, 0, 0),
            "+09:00",
            240,
            128
        );
        const lane = findObject(card, "orbLaneItem");
        const moon = findObject(card, "moonBodyItem");

        card.width = 158;
        card.height = 84;
        wait(0);

        verify(lane !== null);
        verify(card.phasePalette.moonBody.visible);
        verify(moon.x >= 0 && moon.y >= 0);
        verify(moon.x + moon.width <= lane.width + 0.5);
        verify(moon.y + moon.height <= lane.height + 0.5);
    }

    function test_rainOverlaySuppressesStarsAtNight() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 1, 0, 0, 0),
            "+09:00",
            220,
            120,
            rainWeatherState()
        );
        const overlay = findObject(card, "weatherOverlayItem");
        const rainLayer = findObject(card, "rainLayerItem");

        verify(overlay !== null);
        verify(rainLayer !== null);
        verify(overlay.visible);
        verify(rainLayer.visible);
        compare(card.starCount, 0);
        verify(card.weatherScene.kind === "rain");
    }

    function test_snowOverlayCoolsSkyWithoutLosingTextContrast() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 7, 0, 0),
            "+09:00",
            220,
            120,
            snowWeatherState()
        );
        const snowLayer = findObject(card, "snowLayerItem");

        verify(snowLayer !== null);
        verify(snowLayer.visible);
        verify(card.skyTopColor.b > card.skyTopColor.r);
        verify(colorDistance(card.primaryTextColor, card.skyTopColor) > 0.35);
    }

    function test_cloudyDaySuppressesSecondaryDayOrb() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 7, 0, 0),
            "+09:00",
            220,
            120,
            cloudyWeatherState()
        );
        const sun = findObject(card, "sunBodyItem");
        const moon = findObject(card, "moonBodyItem");

        verify(card.phasePalette.sunBody.visible);
        verify(card.phasePalette.moonBody.visible);
        compare(card.suppressSecondaryDayOrb, true);
        compare(card.renderedMoonBody.visible, false);
        compare(sun.visible, true);
        compare(moon.visible, false);
    }

    function test_thunderstormOverlayDoesNotShiftLayout() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 7, 0, 0),
            "+09:00",
            220,
            120,
            clearWeatherState()
        );
        const lane = findObject(card, "orbLaneItem");
        const textColumn = findObject(card, "textColumnItem");
        const previousLaneX = lane.x;
        const previousTextX = textColumn.x;

        card.weatherStateOverride = stormWeatherState();
        wait(0);

        const lightningLayer = findObject(card, "lightningLayerItem");

        verify(lightningLayer !== null);
        verify(lightningLayer.visible);
        compare(lane.x, previousLaneX);
        compare(textColumn.x, previousTextX);
    }

    function test_weatherHudShowsMaxFeelsLikeWithoutSolarMarker() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 14, 0, 0),
            "+09:00",
            220,
            120,
            {
                "available": true,
                "status": "ready",
                "kind": "rain",
                "cloudOpacity": 0.78,
                "rainDensity": 0.62,
                "maxFeelsLikeTemperatureCelsius": 29.4
            }
        );
        const weatherHud = findObject(card, "weatherHudItem");
        const maxFeelsLikeText = findObject(card, "maxFeelsLikeTextItem");
        const glyphText = findObject(card, "weatherConditionGlyphTextItem");
        const solarMarker = findObject(card, "solarMarkerTextItem");

        verify(weatherHud !== null);
        verify(maxFeelsLikeText !== null);
        verify(glyphText !== null);
        verify(solarMarker === null);
        compare(maxFeelsLikeText.text, "29C");
        compare(glyphText.text, "☂");
        verify(colorDistance(maxFeelsLikeText.color, card.primaryTextColor) < 0.001);
        verify(colorDistance(glyphText.color, card.primaryTextColor) < 0.001);
    }

    function test_tokyoSkylineAppearsForTokyoClock() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 14, 0, 0),
            "+09:00",
            220,
            120
        );
        const skyline = findObject(card, "tokyoSkylineItem");
        const nearLayer = findObject(card, "tokyoSkylineNearLayerItem");
        const skytree = findObject(card, "tokyoSkytreeItem");

        verify(skyline !== null);
        verify(nearLayer !== null);
        verify(skytree !== null);
        compare(card.isTokyoClock, true);
        compare(skyline.visible, true);
    }

    function test_tokyoNightLightsAppearAfterDark() {
        const card = createCard(
            "Asia/Tokyo",
            {
                "city": "Tokyo",
                "label": "Tokyo",
                "latitude": 35.654444,
                "longitude": 139.744722
            },
            parts(2026, 4, 8, 21, 0, 0),
            "+09:00",
            220,
            120
        );
        const windowLights = findObject(card, "tokyoWindowLightsLayerItem");
        const firstWindowLight = findObject(card, "tokyoWindowLightItem");
        const beacon = findObject(card, "tokyoTowerBeaconItem");

        verify(windowLights !== null);
        verify(firstWindowLight !== null);
        verify(beacon !== null);
        verify(card.tokyoNightWindowStrength > 0.5);
        compare(windowLights.visible, true);
        compare(beacon.visible, true);
    }

    function test_nonTokyoClockDoesNotShowTokyoSkyline() {
        const card = createCard(
            "Europe/London",
            {
                "city": "London",
                "label": "London",
                "latitude": 51.5072,
                "longitude": -0.1276
            },
            parts(2026, 4, 8, 21, 0, 0),
            "+01:00",
            220,
            120
        );
        const skyline = findObject(card, "tokyoSkylineItem");
        const windowLights = findObject(card, "tokyoWindowLightsLayerItem");

        verify(skyline !== null);
        verify(windowLights !== null);
        compare(card.isTokyoClock, false);
        compare(skyline.visible, false);
        compare(windowLights.visible, false);
    }

    function test_missingWeatherCoordinatesStayAstronomyOnly() {
        const card = createCard(
            "Local",
            {
                "city": "Local",
                "label": "Local",
                "latitude": null,
                "longitude": null
            },
            parts(2026, 4, 12, 22, 0, 0),
            "",
            220,
            120
        );
        const overlay = findObject(card, "weatherOverlayItem");

        compare(card.hasWeatherCoordinates, false);
        compare(card.weatherScene.available, false);
        verify(overlay !== null);
        compare(overlay.visible, false);
    }
}
