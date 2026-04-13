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

    function test_sunStaysLowAtHorizonNearRiseAndSet() {
        const sunrise = SolarPalette.paletteFor(parts(2026, 4, 8, 5, 30, 0), 35.654444, 139.744722, "+09:00");
        const midday = SolarPalette.paletteFor(parts(2026, 4, 8, 12, 0, 0), 35.654444, 139.744722, "+09:00");
        const sunset = SolarPalette.paletteFor(parts(2026, 4, 8, 17, 50, 0), 35.654444, 139.744722, "+09:00");

        verify(sunrise.sunBody.visible);
        verify(midday.sunBody.visible);
        verify(sunset.sunBody.visible);
        verify(sunrise.sunBody.y > midday.sunBody.y);
        verify(sunset.sunBody.y > midday.sunBody.y);
        verify(sunrise.sunBody.x < midday.sunBody.x);
        verify(sunset.sunBody.x > midday.sunBody.x);
    }

    function test_winterDaylightRunsCoolerThanSummerAtHighLatitude() {
        const winter = SolarPalette.paletteFor(parts(2026, 1, 15, 12, 0, 0), 59.3293, 18.0686, "+01:00");
        const summer = SolarPalette.paletteFor(parts(2026, 7, 15, 12, 0, 0), 59.3293, 18.0686, "+02:00");

        compare(winter.phase, "day");
        compare(summer.phase, "day");
        verify((winter.skyTop.b - winter.skyTop.r) > (summer.skyTop.b - summer.skyTop.r));
        verify(summer.contrastBoost > winter.contrastBoost);
    }

    function test_highLatitudeSummerExtendsTwilightBand() {
        const lowLatitudeContext = SolarPalette.seasonalContextFor(parts(2026, 6, 21, 4, 0, 0), 35);
        const highLatitudeContext = SolarPalette.seasonalContextFor(parts(2026, 6, 21, 4, 0, 0), 64);
        const lowLatitudePhase = SolarPalette.phaseFromState({
            "altitude": 6.4,
            "hourAngle": -18
        }, 35, lowLatitudeContext);
        const highLatitudePhase = SolarPalette.phaseFromState({
            "altitude": 6.4,
            "hourAngle": -18
        }, 64, highLatitudeContext);

        compare(lowLatitudePhase, "day");
        compare(highLatitudePhase, "sunrise");
        verify(highLatitudeContext.twilightExtension > lowLatitudeContext.twilightExtension);
    }

    function test_sunriseTwilightProfileStaysWarmerThanDawn() {
        const dawn = SolarPalette.twilightProfileForPhase("dawn", {
            "altitude": -4
        });
        const sunrise = SolarPalette.twilightProfileForPhase("sunrise", {
            "altitude": 0
        });

        verify(sunrise.twilightWarmth > dawn.twilightWarmth);
        verify(dawn.twilightCoolness > sunrise.twilightCoolness);
        verify(sunrise.twilightHorizonBoost > dawn.twilightHorizonBoost);
    }

    function test_duskGetsCoolerAsSunDrops() {
        const earlyDusk = SolarPalette.twilightProfileForPhase("dusk", {
            "altitude": -2.2
        });
        const lateDusk = SolarPalette.twilightProfileForPhase("dusk", {
            "altitude": -5.4
        });

        verify(lateDusk.twilightCoolness > earlyDusk.twilightCoolness);
        verify(lateDusk.twilightWarmth < earlyDusk.twilightWarmth);
        verify(lateDusk.twilightBandOpacity > earlyDusk.twilightBandOpacity);
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
