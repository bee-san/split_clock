.pragma library

const DEG_TO_RAD = Math.PI / 180;
const RAD_TO_DEG = 180 / Math.PI;
const J2000 = 2451545.0;

function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value));
}

function hexColor(value) {
    const text = String(value || "").replace("#", "");

    if (text.length !== 6) {
        return Qt.rgba(1, 1, 1, 1);
    }

    const red = parseInt(text.slice(0, 2), 16) / 255;
    const green = parseInt(text.slice(2, 4), 16) / 255;
    const blue = parseInt(text.slice(4, 6), 16) / 255;

    return Qt.rgba(red, green, blue, 1);
}

function blendColors(baseColor, tintColor, amount) {
    const mix = clamp(amount, 0, 1);

    return Qt.rgba(
        (baseColor.r * (1 - mix)) + (tintColor.r * mix),
        (baseColor.g * (1 - mix)) + (tintColor.g * mix),
        (baseColor.b * (1 - mix)) + (tintColor.b * mix),
        (baseColor.a * (1 - mix)) + (tintColor.a * mix)
    );
}

function parseOffsetHours(offsetText) {
    const text = String(offsetText || "");
    const match = text.match(/([+-])(\d{1,2})(?::?(\d{2}))?/);

    if (!match) {
        return 0;
    }

    const sign = match[1] === "-" ? -1 : 1;
    const hours = Number(match[2] || 0);
    const minutes = Number(match[3] || 0);

    return sign * (hours + (minutes / 60));
}

function extractParts(dateTime) {
    if (dateTime && dateTime.year !== undefined && dateTime.month !== undefined && dateTime.day !== undefined) {
        return {
            year: Number(dateTime.year),
            month: Number(dateTime.month),
            day: Number(dateTime.day),
            hour: Number(dateTime.hour || 0),
            minute: Number(dateTime.minute || 0),
            second: Number(dateTime.second || 0)
        };
    }

    const parts = Qt.formatDateTime(dateTime, "yyyy MM dd HH mm ss").split(" ");

    return {
        year: Number(parts[0]),
        month: Number(parts[1]),
        day: Number(parts[2]),
        hour: Number(parts[3]),
        minute: Number(parts[4]),
        second: Number(parts[5])
    };
}

function dayOfYear(year, month, day) {
    const start = new Date(year, 0, 1);
    const current = new Date(year, month - 1, day);
    const diff = current.getTime() - start.getTime();

    return Math.floor(diff / 86400000) + 1;
}

function normalizeDegrees(value) {
    let normalized = value % 360;

    if (normalized < 0) {
        normalized += 360;
    }

    return normalized;
}

function normalizeSignedDegrees(value) {
    let normalized = normalizeDegrees(value);

    if (normalized > 180) {
        normalized -= 360;
    }

    return normalized;
}

function sinDegrees(value) {
    return Math.sin(value * DEG_TO_RAD);
}

function cosDegrees(value) {
    return Math.cos(value * DEG_TO_RAD);
}

function tanDegrees(value) {
    return Math.tan(value * DEG_TO_RAD);
}

function atan2Degrees(y, x) {
    return Math.atan2(y, x) * RAD_TO_DEG;
}

function asinDegrees(value) {
    return Math.asin(clamp(value, -1, 1)) * RAD_TO_DEG;
}

function acosDegrees(value) {
    return Math.acos(clamp(value, -1, 1)) * RAD_TO_DEG;
}

function julianDayFromLocalParts(parts, offsetText) {
    let year = parts.year;
    let month = parts.month;

    if (month <= 2) {
        year -= 1;
        month += 12;
    }

    const century = Math.floor(year / 100);
    const correction = 2 - century + Math.floor(century / 4);
    const utcHours = parts.hour + (parts.minute / 60) + (parts.second / 3600) - parseOffsetHours(offsetText);
    const dayFraction = utcHours / 24;

    return Math.floor(365.25 * (year + 4716))
        + Math.floor(30.6001 * (month + 1))
        + parts.day
        + correction
        - 1524.5
        + dayFraction;
}

function meanObliquityDegrees(julianCenturies) {
    const seconds = 21.448
        - (46.8150 * julianCenturies)
        - (0.00059 * julianCenturies * julianCenturies)
        + (0.001813 * julianCenturies * julianCenturies * julianCenturies);

    return 23 + (26 / 60) + (seconds / 3600);
}

function meanSiderealTimeDegrees(julianDay) {
    const julianCenturies = (julianDay - J2000) / 36525;

    return normalizeDegrees(
        280.46061837
        + (360.98564736629 * (julianDay - J2000))
        + (0.000387933 * julianCenturies * julianCenturies)
        - ((julianCenturies * julianCenturies * julianCenturies) / 38710000)
    );
}

function horizontalFromEquatorial(rightAscension, declination, latitude, longitude, julianDay) {
    const localSiderealTime = normalizeDegrees(meanSiderealTimeDegrees(julianDay) + longitude);
    const hourAngle = normalizeSignedDegrees(localSiderealTime - rightAscension);
    const latitudeRadians = latitude * DEG_TO_RAD;
    const declinationRadians = declination * DEG_TO_RAD;
    const hourAngleRadians = hourAngle * DEG_TO_RAD;

    const sineAltitude = (Math.sin(latitudeRadians) * Math.sin(declinationRadians))
        + (Math.cos(latitudeRadians) * Math.cos(declinationRadians) * Math.cos(hourAngleRadians));
    const altitude = asinDegrees(sineAltitude);
    const altitudeRadians = altitude * DEG_TO_RAD;
    const denominator = Math.max(1e-6, Math.cos(altitudeRadians) * Math.cos(latitudeRadians));
    const cosineAzimuth = clamp(
        (Math.sin(declinationRadians) - (Math.sin(altitudeRadians) * Math.sin(latitudeRadians))) / denominator,
        -1,
        1
    );

    let azimuth = acosDegrees(cosineAzimuth);

    if (Math.sin(hourAngleRadians) > 0) {
        azimuth = 360 - azimuth;
    }

    const parallacticAngle = atan2Degrees(
        Math.sin(hourAngleRadians),
        (Math.tan(latitudeRadians) * Math.cos(declinationRadians))
            - (Math.sin(declinationRadians) * Math.cos(hourAngleRadians))
    );

    return {
        altitude: altitude,
        azimuth: azimuth,
        hourAngle: hourAngle,
        parallacticAngle: parallacticAngle
    };
}

function eclipticToEquatorial(lambda, beta, obliquity) {
    const lambdaRadians = lambda * DEG_TO_RAD;
    const betaRadians = beta * DEG_TO_RAD;
    const obliquityRadians = obliquity * DEG_TO_RAD;

    const x = Math.cos(lambdaRadians) * Math.cos(betaRadians);
    const y = (Math.sin(lambdaRadians) * Math.cos(betaRadians) * Math.cos(obliquityRadians))
        - (Math.sin(betaRadians) * Math.sin(obliquityRadians));
    const z = (Math.sin(lambdaRadians) * Math.cos(betaRadians) * Math.sin(obliquityRadians))
        + (Math.sin(betaRadians) * Math.cos(obliquityRadians));
    const rightAscension = normalizeDegrees(atan2Degrees(y, x));
    const declination = atan2Degrees(z, Math.sqrt((x * x) + (y * y)));

    return {
        rightAscension: rightAscension,
        declination: declination
    };
}

function solarEquatorialState(julianDay) {
    const julianCenturies = (julianDay - J2000) / 36525;
    const meanLongitude = normalizeDegrees(280.46646 + (36000.76983 * julianCenturies) + (0.0003032 * julianCenturies * julianCenturies));
    const meanAnomaly = normalizeDegrees(357.52911 + (35999.05029 * julianCenturies) - (0.0001537 * julianCenturies * julianCenturies));
    const equationOfCenter = ((1.914602 - (0.004817 * julianCenturies) - (0.000014 * julianCenturies * julianCenturies)) * sinDegrees(meanAnomaly))
        + ((0.019993 - (0.000101 * julianCenturies)) * sinDegrees(2 * meanAnomaly))
        + (0.000289 * sinDegrees(3 * meanAnomaly));
    const trueLongitude = meanLongitude + equationOfCenter;
    const ascendingNode = 125.04 - (1934.136 * julianCenturies);
    const apparentLongitude = trueLongitude - 0.00569 - (0.00478 * sinDegrees(ascendingNode));
    const obliquity = meanObliquityDegrees(julianCenturies) + (0.00256 * cosDegrees(ascendingNode));
    const equatorial = eclipticToEquatorial(apparentLongitude, 0, obliquity);

    return {
        julianCenturies: julianCenturies,
        obliquity: obliquity,
        meanLongitude: meanLongitude,
        meanAnomaly: meanAnomaly,
        eclipticLongitude: apparentLongitude,
        rightAscension: equatorial.rightAscension,
        declination: equatorial.declination
    };
}

function solarState(dateTime, latitude, longitude, offsetText) {
    if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) {
        return null;
    }

    const parts = extractParts(dateTime);
    const julianDay = julianDayFromLocalParts(parts, offsetText);
    const equatorial = solarEquatorialState(julianDay);
    const horizontal = horizontalFromEquatorial(equatorial.rightAscension, equatorial.declination, latitude, longitude, julianDay);

    return {
        julianDay: julianDay,
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth,
        hourAngle: horizontal.hourAngle,
        parallacticAngle: horizontal.parallacticAngle,
        rightAscension: equatorial.rightAscension,
        declination: equatorial.declination,
        eclipticLongitude: equatorial.eclipticLongitude
    };
}

function moonEquatorialState(julianDay, obliquity, solarLongitude, solarMeanAnomaly) {
    const days = julianDay - 2451543.5;
    const ascendingNode = normalizeDegrees(125.1228 - (0.0529538083 * days));
    const inclination = 5.1454;
    const argumentOfPerigee = normalizeDegrees(318.0634 + (0.1643573223 * days));
    const eccentricity = 0.0549;
    const meanAnomaly = normalizeDegrees(115.3654 + (13.0649929509 * days));
    const meanLongitude = normalizeDegrees(ascendingNode + argumentOfPerigee + meanAnomaly);
    const meanElongation = normalizeSignedDegrees(meanLongitude - solarLongitude);
    const argumentOfLatitude = normalizeSignedDegrees(meanLongitude - ascendingNode);
    const eccentricAnomaly = meanAnomaly + ((180 / Math.PI) * eccentricity * sinDegrees(meanAnomaly) * (1 + (eccentricity * cosDegrees(meanAnomaly))));

    const xOrbit = Math.cos(eccentricAnomaly * DEG_TO_RAD) - eccentricity;
    const yOrbit = Math.sin(eccentricAnomaly * DEG_TO_RAD) * Math.sqrt(1 - (eccentricity * eccentricity));
    const trueAnomaly = atan2Degrees(yOrbit, xOrbit);
    let distance = Math.sqrt((xOrbit * xOrbit) + (yOrbit * yOrbit));

    let eclipticLongitude = atan2Degrees(
        (cosDegrees(ascendingNode) * sinDegrees(trueAnomaly + argumentOfPerigee) * cosDegrees(inclination))
            + (sinDegrees(ascendingNode) * cosDegrees(trueAnomaly + argumentOfPerigee)),
        (cosDegrees(ascendingNode) * cosDegrees(trueAnomaly + argumentOfPerigee))
            - (sinDegrees(ascendingNode) * sinDegrees(trueAnomaly + argumentOfPerigee) * cosDegrees(inclination))
    );
    let eclipticLatitude = asinDegrees(sinDegrees(trueAnomaly + argumentOfPerigee) * sinDegrees(inclination));

    eclipticLongitude = normalizeDegrees(eclipticLongitude);

    eclipticLongitude += (-1.274 * sinDegrees(meanAnomaly - (2 * meanElongation)))
        + (0.658 * sinDegrees(2 * meanElongation))
        - (0.186 * sinDegrees(solarMeanAnomaly))
        - (0.059 * sinDegrees((2 * meanAnomaly) - (2 * meanElongation)))
        - (0.057 * sinDegrees(meanAnomaly - (2 * meanElongation) + solarMeanAnomaly))
        + (0.053 * sinDegrees(meanAnomaly + (2 * meanElongation)))
        + (0.046 * sinDegrees((2 * meanElongation) - solarMeanAnomaly))
        + (0.041 * sinDegrees(meanAnomaly - solarMeanAnomaly))
        - (0.035 * sinDegrees(meanElongation))
        - (0.031 * sinDegrees(meanAnomaly + solarMeanAnomaly))
        - (0.015 * sinDegrees((2 * argumentOfLatitude) - (2 * meanElongation)))
        + (0.011 * sinDegrees(meanAnomaly - (4 * meanElongation)));

    eclipticLatitude += (-0.173 * sinDegrees(argumentOfLatitude - (2 * meanElongation)))
        - (0.055 * sinDegrees(meanAnomaly - argumentOfLatitude - (2 * meanElongation)))
        - (0.046 * sinDegrees(meanAnomaly + argumentOfLatitude - (2 * meanElongation)))
        + (0.033 * sinDegrees(argumentOfLatitude + (2 * meanElongation)))
        + (0.017 * sinDegrees((2 * meanAnomaly) + argumentOfLatitude));

    distance += (-0.58 * cosDegrees(meanAnomaly - (2 * meanElongation)))
        - (0.46 * cosDegrees(2 * meanElongation));

    const equatorial = eclipticToEquatorial(normalizeDegrees(eclipticLongitude), eclipticLatitude, obliquity);

    return {
        distance: distance,
        eclipticLongitude: normalizeDegrees(eclipticLongitude),
        eclipticLatitude: eclipticLatitude,
        rightAscension: equatorial.rightAscension,
        declination: equatorial.declination
    };
}

function moonHorizontalState(julianDay, latitude, longitude, solarEquatorial) {
    const equatorial = moonEquatorialState(
        julianDay,
        solarEquatorial.obliquity,
        solarEquatorial.eclipticLongitude,
        solarEquatorial.meanAnomaly
    );
    const horizontal = horizontalFromEquatorial(equatorial.rightAscension, equatorial.declination, latitude, longitude, julianDay);

    return {
        altitude: horizontal.altitude,
        azimuth: horizontal.azimuth,
        hourAngle: horizontal.hourAngle,
        parallacticAngle: horizontal.parallacticAngle,
        rightAscension: equatorial.rightAscension,
        declination: equatorial.declination,
        eclipticLongitude: equatorial.eclipticLongitude,
        eclipticLatitude: equatorial.eclipticLatitude
    };
}

function illuminationFraction(solarPosition, lunarPosition) {
    const cosineElongation = clamp(
        (sinDegrees(solarPosition.declination) * sinDegrees(lunarPosition.declination))
            + (cosDegrees(solarPosition.declination) * cosDegrees(lunarPosition.declination)
                * cosDegrees(solarPosition.rightAscension - lunarPosition.rightAscension)),
        -1,
        1
    );

    return (1 - cosineElongation) / 2;
}

function angularSeparationDegrees(firstPosition, secondPosition) {
    const cosineSeparation = clamp(
        (sinDegrees(firstPosition.declination) * sinDegrees(secondPosition.declination))
            + (cosDegrees(firstPosition.declination) * cosDegrees(secondPosition.declination)
                * cosDegrees(firstPosition.rightAscension - secondPosition.rightAscension)),
        -1,
        1
    );

    return acosDegrees(cosineSeparation);
}

function waxingState(solarPosition, lunarPosition) {
    return normalizeDegrees(lunarPosition.eclipticLongitude - solarPosition.eclipticLongitude) < 180;
}

function terminatorAngle(solarPosition, lunarPosition) {
    const brightLimbAngle = atan2Degrees(
        cosDegrees(solarPosition.declination) * sinDegrees(solarPosition.rightAscension - lunarPosition.rightAscension),
        (sinDegrees(solarPosition.declination) * cosDegrees(lunarPosition.declination))
            - (cosDegrees(solarPosition.declination) * sinDegrees(lunarPosition.declination)
                * cosDegrees(solarPosition.rightAscension - lunarPosition.rightAscension))
    );

    return normalizeSignedDegrees(brightLimbAngle - lunarPosition.parallacticAngle);
}

function bodyLaneState(horizontalState, sizeScale, isVisible) {
    return {
        visible: isVisible,
        x: clamp(0.5 + ((horizontalState.hourAngle / 180) * 0.42), 0.08, 0.92),
        y: clamp(0.82 - ((clamp(horizontalState.altitude, 0, 90) / 90) * 0.66), 0.14, 0.82),
        altitude: horizontalState.altitude,
        azimuth: horizontalState.azimuth,
        sizeScale: sizeScale
    };
}

function emptyBody() {
    return {
        visible: false,
        x: 0.5,
        y: 0.82,
        altitude: -90,
        azimuth: 180,
        sizeScale: 0
    };
}

function seasonalContextFor(dateTime, latitude) {
    const parts = extractParts(dateTime);
    const safeLatitude = latitude === null || latitude === undefined ? 0 : Number(latitude);
    const absoluteLatitude = clamp(Math.abs(safeLatitude), 0, 80);
    const latitudeFactor = clamp((absoluteLatitude - 18) / 50, 0, 1);
    const hemisphere = safeLatitude < 0 ? -1 : 1;
    const seasonalAngle = ((dayOfYear(parts.year, parts.month, parts.day) - 172) / 365.2422) * Math.PI * 2;
    const summerBias = Math.cos(seasonalAngle) * hemisphere;
    const summerStrength = clamp(Math.max(0, summerBias) * latitudeFactor, 0, 1);
    const winterStrength = clamp(Math.max(0, -summerBias) * latitudeFactor, 0, 1);
    const twilightExtension = latitudeFactor * (0.7 + (summerStrength * 1.5));

    return {
        latitudeFactor: latitudeFactor,
        summerStrength: summerStrength,
        winterStrength: winterStrength,
        twilightExtension: twilightExtension
    };
}

function phaseThresholdsForContext(seasonalContext) {
    const context = seasonalContext || seasonalContextFor(extractParts(new Date()), 0);
    const extension = context.twilightExtension || 0;

    return {
        midnightThreshold: -14 - (extension * 0.9),
        nightThreshold: -6 - (extension * 0.55),
        dawnThreshold: -2 - (extension * 0.18),
        sunriseThreshold: 6 + (extension * 0.42)
    };
}

function phaseFromState(state, latitude, seasonalContext) {
    const thresholds = phaseThresholdsForContext(seasonalContext || seasonalContextFor(new Date(), latitude));

    if (state.altitude < thresholds.midnightThreshold) {
        return "midnight";
    }

    if (state.altitude < thresholds.nightThreshold) {
        return "night";
    }

    if (state.altitude < thresholds.dawnThreshold) {
        return state.hourAngle < 0 ? "dawn" : "dusk";
    }

    if (state.altitude < thresholds.sunriseThreshold) {
        return state.hourAngle < 0 ? "sunrise" : "sunset";
    }

    return "day";
}

function fallbackPhase(dateTime) {
    const parts = extractParts(dateTime);
    const hour = parts.hour;

    if (hour < 4) {
        return "midnight";
    }

    if (hour < 6 || hour >= 22) {
        return "night";
    }

    if (hour < 7) {
        return "dawn";
    }

    if (hour < 8) {
        return "sunrise";
    }

    if (hour < 17) {
        return "day";
    }

    if (hour < 19) {
        return "sunset";
    }

    if (hour < 21) {
        return "dusk";
    }

    return "night";
}

function orbitForState(dateTime, state) {
    if (state) {
        const normalizedHourAngle = clamp((state.hourAngle + 100) / 200, 0.08, 0.92);
        const normalizedElevation = clamp((state.altitude + 12) / 70, 0, 1);

        return {
            orbX: normalizedHourAngle,
            orbY: 0.76 - (normalizedElevation * 0.56)
        };
    }

    const parts = extractParts(dateTime);
    const hour = parts.hour;
    const minute = parts.minute;
    const dayProgress = (hour + (minute / 60)) / 24;
    const arcProgress = dayProgress <= 0.5 ? (dayProgress / 0.5) : ((1 - dayProgress) / 0.5);

    return {
        orbX: clamp(dayProgress, 0.08, 0.92),
        orbY: 0.8 - (clamp(arcProgress, 0, 1) * 0.42)
    };
}

function paletteByPhase(phase) {
    switch (phase) {
    case "dawn":
        return {
            phase: "dawn",
            phaseLabel: "Blue Hour",
            accent: hexColor("#5779c7"),
            skyTop: hexColor("#0e1f42"),
            skyMid: hexColor("#274b86"),
            skyBottom: hexColor("#7da1df"),
            horizon: hexColor("#f0a177"),
            horizonGlow: hexColor("#ffbb92"),
            glow: hexColor("#ffd7b2"),
            orbCore: hexColor("#ffd8a8"),
            orbHalo: hexColor("#f29e72"),
            orbRim: hexColor("#fff1d7"),
            orbScale: 0.34,
            starOpacity: 0.26,
            starDensity: 0.34,
            hazeOpacity: 0.34,
            sheenOpacity: 0.12,
            contrastBoost: 0.68,
            textBoost: 0.68,
            vignetteOpacity: 0.18,
            glowOpacity: 0.24,
            twilightWarmth: 0.38,
            twilightCoolness: 0.78,
            twilightBandOpacity: 0.16,
            twilightHorizonBoost: 0.28
        };
    case "sunrise":
        return {
            phase: "sunrise",
            phaseLabel: "Sunrise",
            accent: hexColor("#d9924a"),
            skyTop: hexColor("#2f629d"),
            skyMid: hexColor("#6f94d5"),
            skyBottom: hexColor("#f7d0ae"),
            horizon: hexColor("#f29667"),
            horizonGlow: hexColor("#ffd2a5"),
            glow: hexColor("#ffe7b8"),
            orbCore: hexColor("#fff2cf"),
            orbHalo: hexColor("#f1a35d"),
            orbRim: hexColor("#fffaf0"),
            orbScale: 0.36,
            starOpacity: 0.03,
            starDensity: 0.05,
            hazeOpacity: 0.4,
            sheenOpacity: 0.13,
            contrastBoost: 0.28,
            textBoost: 0.26,
            vignetteOpacity: 0.12,
            glowOpacity: 0.3,
            twilightWarmth: 0.86,
            twilightCoolness: 0.34,
            twilightBandOpacity: 0.22,
            twilightHorizonBoost: 0.48
        };
    case "day":
        return {
            phase: "day",
            phaseLabel: "Daylight",
            accent: hexColor("#5f97e6"),
            skyTop: hexColor("#2e7fd6"),
            skyMid: hexColor("#78b2f0"),
            skyBottom: hexColor("#e8f6ff"),
            horizon: hexColor("#fae7c0"),
            horizonGlow: hexColor("#fff3dc"),
            glow: hexColor("#fff6d0"),
            orbCore: hexColor("#fffbf3"),
            orbHalo: hexColor("#ffe8ae"),
            orbRim: hexColor("#fffdf8"),
            orbScale: 0.32,
            starOpacity: 0,
            starDensity: 0,
            hazeOpacity: 0.18,
            sheenOpacity: 0.08,
            contrastBoost: 0.12,
            textBoost: 0.08,
            vignetteOpacity: 0.08,
            glowOpacity: 0.22,
            twilightWarmth: 0,
            twilightCoolness: 0,
            twilightBandOpacity: 0,
            twilightHorizonBoost: 0
        };
    case "sunset":
        return {
            phase: "sunset",
            phaseLabel: "Sunset",
            accent: hexColor("#ce7647"),
            skyTop: hexColor("#203f6b"),
            skyMid: hexColor("#5e69a3"),
            skyBottom: hexColor("#f8a36e"),
            horizon: hexColor("#ffd1a0"),
            horizonGlow: hexColor("#ffbc83"),
            glow: hexColor("#ffd09a"),
            orbCore: hexColor("#ffe4ad"),
            orbHalo: hexColor("#e57d4c"),
            orbRim: hexColor("#fff3df"),
            orbScale: 0.37,
            starOpacity: 0.05,
            starDensity: 0.08,
            hazeOpacity: 0.42,
            sheenOpacity: 0.15,
            contrastBoost: 0.4,
            textBoost: 0.38,
            vignetteOpacity: 0.14,
            glowOpacity: 0.28,
            twilightWarmth: 0.92,
            twilightCoolness: 0.42,
            twilightBandOpacity: 0.24,
            twilightHorizonBoost: 0.52
        };
    case "dusk":
        return {
            phase: "dusk",
            phaseLabel: "Blue Hour",
            accent: hexColor("#526ec5"),
            skyTop: hexColor("#0e1e42"),
            skyMid: hexColor("#2b467f"),
            skyBottom: hexColor("#5b6dab"),
            horizon: hexColor("#f29975"),
            horizonGlow: hexColor("#f9c29e"),
            glow: hexColor("#f5c7a5"),
            orbCore: hexColor("#ffe2bc"),
            orbHalo: hexColor("#d07a67"),
            orbRim: hexColor("#fff1dd"),
            orbScale: 0.29,
            starOpacity: 0.42,
            starDensity: 0.54,
            hazeOpacity: 0.26,
            sheenOpacity: 0.09,
            contrastBoost: 0.74,
            textBoost: 0.74,
            vignetteOpacity: 0.18,
            glowOpacity: 0.2,
            twilightWarmth: 0.34,
            twilightCoolness: 0.82,
            twilightBandOpacity: 0.18,
            twilightHorizonBoost: 0.24
        };
    case "midnight":
        return {
            phase: "midnight",
            phaseLabel: "Midnight",
            accent: hexColor("#4568b2"),
            skyTop: hexColor("#01040f"),
            skyMid: hexColor("#071630"),
            skyBottom: hexColor("#102654"),
            horizon: hexColor("#183b67"),
            horizonGlow: hexColor("#274d86"),
            glow: hexColor("#cfe2ff"),
            orbCore: hexColor("#f4f8ff"),
            orbHalo: hexColor("#708ed5"),
            orbRim: hexColor("#ffffff"),
            orbScale: 0.23,
            starOpacity: 0.88,
            starDensity: 0.92,
            hazeOpacity: 0.05,
            sheenOpacity: 0.02,
            contrastBoost: 0.96,
            textBoost: 0.96,
            vignetteOpacity: 0.28,
            glowOpacity: 0.09,
            twilightWarmth: 0,
            twilightCoolness: 0,
            twilightBandOpacity: 0,
            twilightHorizonBoost: 0
        };
    case "night":
    default:
        return {
            phase: "night",
            phaseLabel: "Night",
            accent: hexColor("#567abe"),
            skyTop: hexColor("#03101f"),
            skyMid: hexColor("#0b2146"),
            skyBottom: hexColor("#16345e"),
            horizon: hexColor("#23527c"),
            horizonGlow: hexColor("#4a77aa"),
            glow: hexColor("#c7daf6"),
            orbCore: hexColor("#f6fbff"),
            orbHalo: hexColor("#84a4dd"),
            orbRim: hexColor("#ffffff"),
            orbScale: 0.24,
            starOpacity: 0.82,
            starDensity: 0.78,
            hazeOpacity: 0.1,
            sheenOpacity: 0.03,
            contrastBoost: 0.9,
            textBoost: 0.88,
            vignetteOpacity: 0.22,
            glowOpacity: 0.12,
            twilightWarmth: 0,
            twilightCoolness: 0,
            twilightBandOpacity: 0,
            twilightHorizonBoost: 0
        };
    }
}

function applySeasonalAdjustments(basePalette, seasonalContext, phase) {
    const context = seasonalContext || seasonalContextFor(new Date(), 0);
    const summerWarmth = context.summerStrength * (phase === "day" ? 0.24 : 0.14);
    const winterCoolness = context.winterStrength * (phase === "day" ? 0.32 : 0.16);
    const highLatitudeFactor = context.latitudeFactor || 0;

    return {
        phase: basePalette.phase,
        phaseLabel: basePalette.phaseLabel,
        accent: blendColors(blendColors(basePalette.accent, hexColor("#6ca6f0"), summerWarmth * 0.4), hexColor("#5f8fd7"), winterCoolness * 0.26),
        skyTop: blendColors(blendColors(basePalette.skyTop, hexColor("#3b8be0"), summerWarmth * 0.18), hexColor("#2a6ed8"), winterCoolness * 0.3),
        skyMid: blendColors(blendColors(basePalette.skyMid, hexColor("#8fc3ff"), summerWarmth * 0.12), hexColor("#99b7e8"), winterCoolness * 0.28),
        skyBottom: blendColors(blendColors(basePalette.skyBottom, hexColor("#fff0cd"), summerWarmth * 0.1), hexColor("#edf5ff"), winterCoolness * 0.24),
        horizon: blendColors(basePalette.horizon, hexColor("#ffe3bf"), summerWarmth * 0.16),
        horizonGlow: blendColors(blendColors(basePalette.horizonGlow, hexColor("#ffd4a0"), summerWarmth * 0.18), hexColor("#dfeeff"), winterCoolness * 0.1),
        glow: blendColors(blendColors(basePalette.glow, hexColor("#fff0c5"), summerWarmth * 0.14), hexColor("#edf5ff"), winterCoolness * 0.14),
        orbCore: blendColors(basePalette.orbCore, hexColor("#eef5ff"), winterCoolness * 0.16),
        orbHalo: blendColors(blendColors(basePalette.orbHalo, hexColor("#ffcf86"), summerWarmth * 0.16), hexColor("#b9d0ef"), winterCoolness * 0.18),
        orbRim: blendColors(basePalette.orbRim, hexColor("#eef5ff"), winterCoolness * 0.12),
        orbScale: basePalette.orbScale,
        starOpacity: clamp(basePalette.starOpacity + (highLatitudeFactor * 0.04) - (summerWarmth * 0.03), 0, 1),
        starDensity: clamp(basePalette.starDensity + (highLatitudeFactor * 0.06) - (summerWarmth * 0.04), 0, 1),
        hazeOpacity: clamp(basePalette.hazeOpacity + (summerWarmth * 0.04) + (winterCoolness * 0.02), 0, 1),
        sheenOpacity: clamp(basePalette.sheenOpacity + (summerWarmth * 0.04), 0, 1),
        contrastBoost: clamp(basePalette.contrastBoost + (summerWarmth * 0.1) + (winterCoolness * 0.04), 0, 1),
        textBoost: clamp(basePalette.textBoost + (winterCoolness * 0.06), 0, 1),
        vignetteOpacity: clamp(basePalette.vignetteOpacity + (winterCoolness * 0.04), 0, 1),
        glowOpacity: clamp(basePalette.glowOpacity + (summerWarmth * 0.06) - (winterCoolness * 0.03), 0, 1),
        twilightWarmth: clamp(basePalette.twilightWarmth + (summerWarmth * 0.08), 0, 1),
        twilightCoolness: clamp(basePalette.twilightCoolness + (winterCoolness * 0.08) + (highLatitudeFactor * 0.04), 0, 1),
        twilightBandOpacity: clamp(basePalette.twilightBandOpacity + (context.twilightExtension * 0.04), 0, 1),
        twilightHorizonBoost: clamp(basePalette.twilightHorizonBoost + (context.twilightExtension * 0.06), 0, 1)
    };
}

function twilightProfileForPhase(phase, solarPosition, seasonalContext) {
    if (phase !== "dawn" && phase !== "sunrise" && phase !== "sunset" && phase !== "dusk") {
        return {
            twilightWarmth: 0,
            twilightCoolness: 0,
            twilightBandOpacity: 0,
            twilightHorizonBoost: 0
        };
    }

    if (!solarPosition) {
        return paletteByPhase(phase);
    }

    const context = seasonalContext || seasonalContextFor(new Date(), 0);
    const altitude = solarPosition.altitude;

    switch (phase) {
    case "dawn": {
        const progress = clamp((altitude + 6) / 4, 0, 1);

        return {
            twilightWarmth: clamp(0.3 + (progress * 0.16) + (context.summerStrength * 0.06), 0, 1),
            twilightCoolness: clamp(0.82 - (progress * 0.1) + (context.winterStrength * 0.08) + (context.latitudeFactor * 0.04), 0, 1),
            twilightBandOpacity: clamp(0.14 + (progress * 0.06) + (context.twilightExtension * 0.03), 0, 1),
            twilightHorizonBoost: clamp(0.24 + (progress * 0.1) + (context.twilightExtension * 0.05), 0, 1)
        };
    }
    case "sunrise": {
        const progress = clamp((altitude + 2) / 8, 0, 1);

        return {
            twilightWarmth: clamp(0.9 - (progress * 0.2) + (context.summerStrength * 0.08), 0, 1),
            twilightCoolness: clamp(0.42 - (progress * 0.18) + (context.winterStrength * 0.06), 0, 1),
            twilightBandOpacity: clamp(0.24 - (progress * 0.1) + (context.twilightExtension * 0.03), 0, 1),
            twilightHorizonBoost: clamp(0.5 - (progress * 0.14) + (context.twilightExtension * 0.04), 0, 1)
        };
    }
    case "sunset": {
        const progress = clamp((6 - altitude) / 8, 0, 1);

        return {
            twilightWarmth: clamp(0.74 + (progress * 0.18) + (context.summerStrength * 0.08), 0, 1),
            twilightCoolness: clamp(0.28 + (progress * 0.24) + (context.winterStrength * 0.06), 0, 1),
            twilightBandOpacity: clamp(0.18 + (progress * 0.1) + (context.twilightExtension * 0.03), 0, 1),
            twilightHorizonBoost: clamp(0.34 + (progress * 0.18) + (context.twilightExtension * 0.04), 0, 1)
        };
    }
    case "dusk":
    default: {
        const progress = clamp((-2 - altitude) / 4, 0, 1);

        return {
            twilightWarmth: clamp(0.44 - (progress * 0.12) + (context.summerStrength * 0.04), 0, 1),
            twilightCoolness: clamp(0.64 + (progress * 0.18) + (context.winterStrength * 0.08) + (context.latitudeFactor * 0.04), 0, 1),
            twilightBandOpacity: clamp(0.16 + (progress * 0.06) + (context.twilightExtension * 0.03), 0, 1),
            twilightHorizonBoost: clamp(0.28 - (progress * 0.08) + (context.twilightExtension * 0.03), 0, 1)
        };
    }
    }
}

function simplifiedCelestialState(dateTime, basePalette, phase) {
    const orbit = orbitForState(dateTime, null);
    const isNightLike = phase === "night" || phase === "midnight";

    const sunBody = emptyBody();
    const moonBody = emptyBody();

    if (isNightLike) {
        moonBody.visible = true;
        moonBody.x = orbit.orbX;
        moonBody.y = orbit.orbY;
        moonBody.altitude = 28;
        moonBody.azimuth = 180;
        moonBody.sizeScale = basePalette.orbScale * 0.96;
        moonBody.illuminationFraction = 0.3;
        moonBody.terminatorAngle = -18;
        moonBody.isWaxing = true;
        moonBody.isSimplified = true;
    } else {
        sunBody.visible = true;
        sunBody.x = orbit.orbX;
        sunBody.y = orbit.orbY;
        sunBody.altitude = 35;
        sunBody.azimuth = 180;
        sunBody.sizeScale = basePalette.orbScale;
        sunBody.isSimplified = true;
    }

    return {
        usesSimplifiedCelestial: true,
        orbX: orbit.orbX,
        orbY: orbit.orbY,
        allowBodyOverlap: false,
        angularSeparationDegrees: 180,
        sunBody: sunBody,
        moonBody: moonBody
    };
}

function remoteCelestialState(dateTime, latitude, longitude, offsetText, basePalette) {
    const parts = extractParts(dateTime);
    const julianDay = julianDayFromLocalParts(parts, offsetText);
    const solarEquatorial = solarEquatorialState(julianDay);
    const sunHorizontal = horizontalFromEquatorial(solarEquatorial.rightAscension, solarEquatorial.declination, latitude, longitude, julianDay);
    const lunarState = moonHorizontalState(julianDay, latitude, longitude, solarEquatorial);
    const sunVisible = sunHorizontal.altitude > 0;
    const moonVisible = lunarState.altitude > 0;
    const sunBody = bodyLaneState(sunHorizontal, basePalette.orbScale * (moonVisible ? 1.02 : 1.08), sunVisible);
    const moonBody = bodyLaneState(lunarState, basePalette.orbScale * (sunVisible ? 0.72 : 0.9), moonVisible);
    const separationDegrees = angularSeparationDegrees(solarEquatorial, lunarState);

    moonBody.illuminationFraction = illuminationFraction(solarEquatorial, lunarState);
    moonBody.terminatorAngle = terminatorAngle(solarEquatorial, lunarState);
    moonBody.isWaxing = waxingState(solarEquatorial, lunarState);
    moonBody.isSimplified = false;

    sunBody.isSimplified = false;

    return {
        usesSimplifiedCelestial: false,
        orbX: sunBody.visible ? sunBody.x : moonBody.x,
        orbY: sunBody.visible ? sunBody.y : moonBody.y,
        allowBodyOverlap: sunVisible && moonVisible && separationDegrees < 0.85 && moonBody.illuminationFraction < 0.08,
        angularSeparationDegrees: separationDegrees,
        sunBody: sunBody,
        moonBody: moonBody
    };
}

function decoratePalette(basePalette, celestialState, twilightProfile, seasonalContext) {
    const context = seasonalContext || seasonalContextFor(new Date(), 0);

    return {
        phase: basePalette.phase,
        phaseLabel: basePalette.phaseLabel,
        accent: basePalette.accent,
        skyTop: basePalette.skyTop,
        skyMid: basePalette.skyMid,
        skyBottom: basePalette.skyBottom,
        horizon: basePalette.horizon,
        horizonGlow: basePalette.horizonGlow,
        glow: basePalette.glow,
        orbCore: basePalette.orbCore,
        orbHalo: basePalette.orbHalo,
        orbRim: basePalette.orbRim,
        orbScale: basePalette.orbScale,
        starOpacity: basePalette.starOpacity,
        starDensity: basePalette.starDensity,
        hazeOpacity: basePalette.hazeOpacity,
        sheenOpacity: basePalette.sheenOpacity,
        contrastBoost: basePalette.contrastBoost,
        textBoost: basePalette.textBoost,
        vignetteOpacity: basePalette.vignetteOpacity,
        glowOpacity: basePalette.glowOpacity,
        twilightWarmth: twilightProfile.twilightWarmth,
        twilightCoolness: twilightProfile.twilightCoolness,
        twilightBandOpacity: twilightProfile.twilightBandOpacity,
        twilightHorizonBoost: twilightProfile.twilightHorizonBoost,
        summerStrength: context.summerStrength,
        winterStrength: context.winterStrength,
        latitudeFactor: context.latitudeFactor,
        usesSimplifiedCelestial: celestialState.usesSimplifiedCelestial,
        orbX: celestialState.orbX,
        orbY: celestialState.orbY,
        allowBodyOverlap: celestialState.allowBodyOverlap === true,
        angularSeparationDegrees: celestialState.angularSeparationDegrees,
        sunBody: celestialState.sunBody,
        moonBody: celestialState.moonBody
    };
}

function paletteFor(dateTime, latitude, longitude, offsetText) {
    const solarPosition = solarState(dateTime, latitude, longitude, offsetText);
    const seasonalContext = seasonalContextFor(dateTime, latitude);
    const phase = solarPosition ? phaseFromState(solarPosition, latitude, seasonalContext) : fallbackPhase(dateTime);
    const basePalette = applySeasonalAdjustments(paletteByPhase(phase), seasonalContext, phase);
    const twilightProfile = twilightProfileForPhase(phase, solarPosition, seasonalContext);
    const celestialState = solarPosition
        ? remoteCelestialState(dateTime, latitude, longitude, offsetText, basePalette)
        : simplifiedCelestialState(dateTime, basePalette, phase);

    return decoratePalette(basePalette, celestialState, twilightProfile, seasonalContext);
}
