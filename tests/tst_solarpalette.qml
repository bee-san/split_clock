import QtQuick 2.15
import QtTest 1.2

import "../contents/ui/SolarPalette.js" as SolarPalette

TestCase {
    name: "SolarPalette"

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

    function test_fullMoonNight_remoteTokyo() {
        const palette = SolarPalette.paletteFor(parts(2026, 4, 1, 0, 0, 0), 35.654444, 139.744722, "+09:00");

        verify(!palette.usesSimplifiedCelestial);
        verify(palette.moonBody.visible);
        verify(!palette.sunBody.visible);
        verify(palette.moonBody.illuminationFraction > 0.97);
        verify(palette.moonBody.altitude > 45);
    }

    function test_crescentNight_remoteTokyo() {
        const palette = SolarPalette.paletteFor(parts(2026, 4, 12, 3, 0, 0), 35.654444, 139.744722, "+09:00");

        verify(palette.moonBody.visible);
        verify(!palette.sunBody.visible);
        verify(palette.moonBody.illuminationFraction > 0.2);
        verify(palette.moonBody.illuminationFraction < 0.45);
        compare(palette.moonBody.isWaxing, false);
    }

    function test_daytimeMoonVisibleWithSun_remoteTokyo() {
        const palette = SolarPalette.paletteFor(parts(2026, 4, 8, 7, 0, 0), 35.654444, 139.744722, "+09:00");

        verify(palette.sunBody.visible);
        verify(palette.moonBody.visible);
        compare(palette.allowBodyOverlap, false);
        verify(palette.sunBody.altitude > 10);
        verify(palette.moonBody.altitude > 10);
        verify(palette.moonBody.sizeScale < palette.sunBody.sizeScale);
    }

    function test_nightWithMoonBelowHorizon_remotePhoenix() {
        const palette = SolarPalette.paletteFor(parts(2026, 4, 3, 20, 0, 0), 33.4484, -112.074, "-07:00");

        verify(!palette.sunBody.visible);
        verify(!palette.moonBody.visible);
        verify(palette.moonBody.altitude < 0);
        compare(palette.phase, "midnight");
    }

    function test_localFallbackStaysSimplified() {
        const palette = SolarPalette.paletteFor(parts(2026, 4, 12, 22, 0, 0), null, null, "");

        verify(palette.usesSimplifiedCelestial);
        verify(palette.moonBody.visible);
        compare(palette.moonBody.isSimplified, true);
        compare(palette.sunBody.visible, false);
    }
}
