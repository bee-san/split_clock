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

    function createCard(zoneId, entry, state, offset, width, height) {
        clockParts = state;
        clockOffset = offset;

        const card = createTemporaryObject(timeCardComponent, testCase, {
            "timeZoneId": zoneId,
            "entry": entry,
            "width": width || 220,
            "height": height || 120
        });

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
}
