import QtQuick 2.15
import QtTest 1.2

import "../contents/ui"

TestCase {
    id: testCase

    name: "CelestialBody"
    when: windowShown

    function makeBodyData(overrides) {
        const body = {
            "visible": true,
            "illuminationFraction": 1,
            "isWaxing": true,
            "terminatorAngle": 0,
            "isSimplified": false
        };

        const safeOverrides = overrides || {};

        for (const key in safeOverrides) {
            body[key] = safeOverrides[key];
        }

        return body;
    }

    function createMoon(overrides) {
        const moon = createTemporaryObject(moonComponent, testCase, {
            "bodyData": makeBodyData(overrides || {})
        });

        verify(moon !== null);
        wait(0);
        return moon;
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

    function grabImage(item) {
        let ready = false;
        let image = null;
        let errorText = "";

        item.grabToImage(function(result) {
            image = result.image;
            errorText = result.errorString || "";
            ready = true;
        });

        for (let attempt = 0; attempt < 100 && !ready; attempt += 1) {
            wait(20);
        }

        verify(ready, errorText);
        verify(image !== null, errorText);
        return image;
    }

    function fuzzyCompare(actualValue, expectedValue, tolerance) {
        return Math.abs(actualValue - expectedValue) <= tolerance;
    }

    Component {
        id: moonComponent

        CelestialBody {
            moon: true
            width: 120
            height: 120
            glowOpacity: 0
            rimOpacity: 0
            haloColor: Qt.rgba(0, 0, 0, 0)
            coreColor: Qt.rgba(0.94, 0.96, 1, 1)
            rimColor: Qt.rgba(0.74, 0.78, 0.86, 1)
            shadowColor: Qt.rgba(0.04, 0.05, 0.08, 1)
        }
    }

    function test_fullMoonUsesHeadOnLightVector() {
        const moon = createMoon({
            "illuminationFraction": 1,
            "isWaxing": true
        });
        const surface = findObject(moon, "moonSurfaceItem");
        const renderer = findObject(moon, "moonPhaseRenderer");

        verify(surface !== null);
        verify(renderer !== null);
        grabImage(surface);
        compare(moon.litFromRight, true);
        verify(fuzzyCompare(moon.phaseVectorX, 0, 0.0001));
        verify(fuzzyCompare(moon.phaseVectorZ, 1, 0.0001));
        verify(fuzzyCompare(moon.phaseCurveScale, 1, 0.0001));
    }

    function test_waningCrescentFlipsLightVectorLeft() {
        const moon = createMoon({
            "illuminationFraction": 0.3,
            "isWaxing": false
        });
        const surface = findObject(moon, "moonSurfaceItem");
        const renderer = findObject(moon, "moonPhaseRenderer");

        verify(surface !== null);
        verify(renderer !== null);
        grabImage(surface);
        compare(moon.litFromRight, false);
        verify(moon.phaseVectorX < 0);
        verify(moon.phaseVectorZ < 0);
        verify(fuzzyCompare(moon.phaseCurveScale, 0.4, 0.0001));
    }

    function test_waxingGibbousUsesPositiveDepth() {
        const moon = createMoon({
            "illuminationFraction": 0.75,
            "isWaxing": true
        });
        const surface = findObject(moon, "moonSurfaceItem");
        const renderer = findObject(moon, "moonPhaseRenderer");

        verify(surface !== null);
        verify(renderer !== null);
        grabImage(surface);
        compare(moon.litFromRight, true);
        verify(moon.phaseVectorX > 0);
        verify(moon.phaseVectorZ > 0);
        verify(fuzzyCompare(moon.phaseCurveScale, 0.5, 0.0001));
    }

    function test_simplifiedMoonUsesCurvedPhaseRenderer() {
        const moon = createMoon({
            "illuminationFraction": 0.32,
            "isWaxing": true,
            "isSimplified": true,
            "terminatorAngle": -18
        });
        const surface = findObject(moon, "moonSurfaceItem");
        const renderer = findObject(moon, "moonPhaseRenderer");

        verify(surface !== null);
        verify(renderer !== null);
        grabImage(surface);
        compare(moon.simplifiedMoon, true);
        verify(moon.phaseVectorX > 0);
        verify(moon.phaseVectorZ < 0);
        verify(moon.phaseCurveScale > 0.3);
        verify(fuzzyCompare(moon.surfaceRotation, -18, 0.0001));
    }
}
