.pragma library

const CLEAR_KIND = "clear";
const CLOUDY_KIND = "cloudy";
const FOG_KIND = "fog";
const RAIN_KIND = "rain";
const SNOW_KIND = "snow";
const THUNDERSTORM_KIND = "thunderstorm";
const KIND_SEVERITY = {
    "clear": 0,
    "cloudy": 1,
    "fog": 2,
    "rain": 3,
    "snow": 4,
    "thunderstorm": 5
};
const DOMINANT_DAY_AVERAGE_FIELDS = [
    "precipitation",
    "rain",
    "showers",
    "snowfall",
    "cloud_cover",
    "relative_humidity_2m",
    "wind_speed_10m",
    "wind_direction_10m"
];

function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value));
}

function numeric(value, fallbackValue) {
    const number = Number(value);
    return isFinite(number) ? number : fallbackValue;
}

function lerp(fromValue, toValue, amount) {
    const progress = clamp(amount, 0, 1);
    return numeric(fromValue, 0) + ((numeric(toValue, 0) - numeric(fromValue, 0)) * progress);
}

function shortestAngleDelta(fromDegrees, toDegrees) {
    let delta = (numeric(toDegrees, 0) - numeric(fromDegrees, 0) + 180) % 360;

    if (delta < 0) {
        delta += 360;
    }

    return delta - 180;
}

function blendAngleDegrees(fromDegrees, toDegrees, amount) {
    let blended = numeric(fromDegrees, 0) + (shortestAngleDelta(fromDegrees, toDegrees) * clamp(amount, 0, 1));

    blended %= 360;

    if (blended < 0) {
        blended += 360;
    }

    return blended;
}

function discreteTransitionValue(fromValue, toValue, amount, threshold) {
    return clamp(amount, 0, 1) >= numeric(threshold, 0.5) ? toValue : fromValue;
}

const BLENDED_NUMERIC_KEYS = [
    "cloudCover",
    "cloudOpacity",
    "cloudBandCount",
    "cloudBreakFactor",
    "cloudShadowStrength",
    "celestialVeilOpacity",
    "orbOcclusionOpacity",
    "orbOcclusionBands",
    "fogOpacity",
    "fogDepth",
    "humidity",
    "humidityHaze",
    "humidityBloom",
    "rainAmount",
    "rainDensity",
    "snowAmount",
    "snowDensity",
    "storminess",
    "windSpeed",
    "windDrift",
    "motionStrength",
    "lightningCadence",
    "skyDimming",
    "contrastSoftening",
    "coolTint",
    "starVisibilityFactor",
    "sunGlowFactor",
    "moonGlowFactor",
    "horizonFade",
    "clearingStrength",
    "cloudSpeed"
];

function sceneKind(value) {
    const text = String(value || CLEAR_KIND);

    if (text === CLOUDY_KIND || text === FOG_KIND || text === RAIN_KIND || text === SNOW_KIND || text === THUNDERSTORM_KIND) {
        return text;
    }

    return CLEAR_KIND;
}

function defaultSceneState() {
    return {
        "available": false,
        "status": "inactive",
        "kind": CLEAR_KIND,
        "outsideHoursSignalKind": "",
        "outsideHoursSignalLabel": "",
        "conditionLabel": "Unavailable",
        "isDay": true,
        "rawWeatherCode": -1,
        "observationTime": "",
        "cloudCover": 0,
        "cloudOpacity": 0,
        "cloudBandCount": 0,
        "cloudFamily": "none",
        "cloudBreakFactor": 1,
        "cloudShadowStrength": 0,
        "celestialVeilOpacity": 0,
        "orbOcclusionOpacity": 0,
        "orbOcclusionBands": 0,
        "fogOpacity": 0,
        "fogDepth": 0,
        "humidity": 0,
        "humidityHaze": 0,
        "humidityBloom": 0,
        "rainAmount": 0,
        "rainDensity": 0,
        "rainBand": "none",
        "snowAmount": 0,
        "snowDensity": 0,
        "snowBand": "none",
        "storminess": 0,
        "lightning": false,
        "windSpeed": 0,
        "windDirectionDegrees": 0,
        "windDrift": 0,
        "motionStrength": 0,
        "lightningCadence": 1,
        "skyDimming": 0,
        "contrastSoftening": 0,
        "coolTint": 0,
        "starVisibilityFactor": 1,
        "sunGlowFactor": 1,
        "moonGlowFactor": 1,
        "horizonFade": 0,
        "clearingStrength": 0,
        "cloudSpeed": 0.12,
        "postRainClearingEligible": true
    };
}

function normalizeSceneState(sceneState) {
    const normalized = defaultSceneState();
    const source = sceneState || {};

    for (const key in source) {
        normalized[key] = source[key];
    }

    normalized.kind = sceneKind(normalized.kind);
    normalized.available = normalized.available === true;
    normalized.outsideHoursSignalKind = String(normalized.outsideHoursSignalKind || "");
    normalized.outsideHoursSignalLabel = String(normalized.outsideHoursSignalLabel || "");
    normalized.isDay = normalized.isDay !== false;
    normalized.rawWeatherCode = Math.round(numeric(normalized.rawWeatherCode, -1));
    normalized.cloudCover = clamp(numeric(normalized.cloudCover, 0), 0, 1);
    normalized.cloudOpacity = clamp(numeric(normalized.cloudOpacity, 0), 0, 1);
    normalized.cloudBandCount = Math.max(0, Math.min(6, Math.round(numeric(normalized.cloudBandCount, 0))));
    normalized.cloudFamily = String(normalized.cloudFamily || "none");
    normalized.cloudBreakFactor = clamp(numeric(normalized.cloudBreakFactor, 1), 0, 1);
    normalized.cloudShadowStrength = clamp(numeric(normalized.cloudShadowStrength, 0), 0, 1);
    normalized.celestialVeilOpacity = clamp(numeric(normalized.celestialVeilOpacity, 0), 0, 1);
    normalized.orbOcclusionOpacity = clamp(numeric(normalized.orbOcclusionOpacity, 0), 0, 1);
    normalized.orbOcclusionBands = Math.max(0, Math.min(6, Math.round(numeric(normalized.orbOcclusionBands, 0))));
    normalized.fogOpacity = clamp(numeric(normalized.fogOpacity, 0), 0, 1);
    normalized.fogDepth = clamp(numeric(normalized.fogDepth, 0), 0, 1);
    normalized.humidity = clamp(numeric(normalized.humidity, 0), 0, 1);
    normalized.humidityHaze = clamp(numeric(normalized.humidityHaze, 0), 0, 1);
    normalized.humidityBloom = clamp(numeric(normalized.humidityBloom, 0), 0, 1);
    normalized.rainAmount = Math.max(0, numeric(normalized.rainAmount, 0));
    normalized.rainDensity = clamp(numeric(normalized.rainDensity, 0), 0, 1);
    normalized.rainBand = String(normalized.rainBand || "none");
    normalized.snowAmount = Math.max(0, numeric(normalized.snowAmount, 0));
    normalized.snowDensity = clamp(numeric(normalized.snowDensity, 0), 0, 1);
    normalized.snowBand = String(normalized.snowBand || "none");
    normalized.storminess = clamp(numeric(normalized.storminess, 0), 0, 1);
    normalized.lightning = normalized.lightning === true;
    normalized.windSpeed = Math.max(0, numeric(normalized.windSpeed, 0));
    normalized.windDirectionDegrees = ((numeric(normalized.windDirectionDegrees, 0) % 360) + 360) % 360;
    normalized.windDrift = clamp(numeric(normalized.windDrift, 0), -1, 1);
    normalized.motionStrength = clamp(numeric(normalized.motionStrength, 0), 0, 1);
    normalized.lightningCadence = clamp(numeric(normalized.lightningCadence, 1), 0.3, 1.4);
    normalized.skyDimming = clamp(numeric(normalized.skyDimming, 0), 0, 1);
    normalized.contrastSoftening = clamp(numeric(normalized.contrastSoftening, 0), 0, 1);
    normalized.coolTint = clamp(numeric(normalized.coolTint, 0), 0, 1);
    normalized.starVisibilityFactor = clamp(numeric(normalized.starVisibilityFactor, 1), 0, 1);
    normalized.sunGlowFactor = clamp(numeric(normalized.sunGlowFactor, 1), 0, 1);
    normalized.moonGlowFactor = clamp(numeric(normalized.moonGlowFactor, 1), 0, 1);
    normalized.horizonFade = clamp(numeric(normalized.horizonFade, 0), 0, 1);
    normalized.clearingStrength = clamp(numeric(normalized.clearingStrength, 0), 0, 1);
    normalized.cloudSpeed = clamp(numeric(normalized.cloudSpeed, 0.12), 0.04, 0.48);
    normalized.postRainClearingEligible = normalized.postRainClearingEligible !== false;
    normalized.status = String(normalized.status || "inactive");
    normalized.conditionLabel = String(normalized.conditionLabel || "Unknown");
    normalized.observationTime = String(normalized.observationTime || "");

    return normalized;
}

function sceneDifferenceScore(firstScene, secondScene) {
    const first = normalizeSceneState(firstScene);
    const second = normalizeSceneState(secondScene);
    let score = 0;

    score += Math.abs(first.cloudOpacity - second.cloudOpacity) * 0.26;
    score += Math.abs(first.cloudBreakFactor - second.cloudBreakFactor) * 0.14;
    score += Math.abs(first.cloudShadowStrength - second.cloudShadowStrength) * 0.12;
    score += Math.abs(first.fogOpacity - second.fogOpacity) * 0.22;
    score += Math.abs(first.fogDepth - second.fogDepth) * 0.12;
    score += Math.abs(first.humidityHaze - second.humidityHaze) * 0.1;
    score += Math.abs(first.humidityBloom - second.humidityBloom) * 0.08;
    score += Math.abs(first.rainDensity - second.rainDensity) * 0.18;
    score += Math.abs(first.snowDensity - second.snowDensity) * 0.18;
    score += Math.abs(first.storminess - second.storminess) * 0.2;
    score += Math.abs(first.windDrift - second.windDrift) * 0.12;
    score += Math.abs(first.motionStrength - second.motionStrength) * 0.1;
    score += Math.abs(first.skyDimming - second.skyDimming) * 0.1;
    score += Math.abs(first.contrastSoftening - second.contrastSoftening) * 0.08;
    score += Math.abs(first.coolTint - second.coolTint) * 0.06;
    score += Math.abs(first.sunGlowFactor - second.sunGlowFactor) * 0.08;
    score += Math.abs(first.moonGlowFactor - second.moonGlowFactor) * 0.06;
    score += Math.abs(first.horizonFade - second.horizonFade) * 0.08;
    score += Math.abs(first.clearingStrength - second.clearingStrength) * 0.1;

    if (first.kind !== second.kind) {
        score += 0.46;
    }

    if (first.cloudFamily !== second.cloudFamily) {
        score += 0.24;
    }

    if (first.rainBand !== second.rainBand) {
        score += 0.18;
    }

    if (first.snowBand !== second.snowBand) {
        score += 0.18;
    }

    if (first.lightning !== second.lightning) {
        score += 0.22;
    }

    if (first.available !== second.available) {
        score += 0.14;
    }

    return score;
}

function blendSceneStates(firstScene, secondScene, amount) {
    const from = normalizeSceneState(firstScene);
    const to = normalizeSceneState(secondScene);
    const progress = clamp(amount, 0, 1);
    const blended = defaultSceneState();

    for (let index = 0; index < BLENDED_NUMERIC_KEYS.length; index += 1) {
        const key = BLENDED_NUMERIC_KEYS[index];
        blended[key] = lerp(from[key], to[key], progress);
    }

    blended.available = discreteTransitionValue(from.available, to.available, progress, 0.34);
    blended.status = discreteTransitionValue(from.status, to.status, progress, 0.52);
    blended.kind = discreteTransitionValue(from.kind, to.kind, progress, 0.5);
    blended.conditionLabel = discreteTransitionValue(from.conditionLabel, to.conditionLabel, progress, 0.56);
    blended.isDay = discreteTransitionValue(from.isDay, to.isDay, progress, 0.5);
    blended.rawWeatherCode = discreteTransitionValue(from.rawWeatherCode, to.rawWeatherCode, progress, 0.5);
    blended.observationTime = discreteTransitionValue(from.observationTime, to.observationTime, progress, 0.6);
    blended.cloudFamily = discreteTransitionValue(from.cloudFamily, to.cloudFamily, progress, 0.42);
    blended.rainBand = discreteTransitionValue(from.rainBand, to.rainBand, progress, 0.48);
    blended.snowBand = discreteTransitionValue(from.snowBand, to.snowBand, progress, 0.48);
    blended.lightning = discreteTransitionValue(from.lightning, to.lightning, progress, 0.44);
    blended.windDirectionDegrees = blendAngleDegrees(from.windDirectionDegrees, to.windDirectionDegrees, progress);

    return normalizeSceneState(blended);
}

function eligibleForWeather(latitude, longitude, timeZoneId) {
    if (String(timeZoneId || "") === "Local") {
        return false;
    }

    if (latitude === null || latitude === undefined || longitude === null || longitude === undefined) {
        return false;
    }

    return isFinite(Number(latitude)) && isFinite(Number(longitude));
}

function severityForKind(kind) {
    return KIND_SEVERITY[sceneKind(kind)] || 0;
}

function weatherCodePriority(code) {
    const weatherCode = Math.round(numeric(code, -1));

    return (severityForKind(kindForWeatherCode(weatherCode)) * 1000) + Math.max(0, weatherCode);
}

function averageHourlyField(samples, fieldName) {
    if (!samples || samples.length === 0) {
        return 0;
    }

    let total = 0;

    for (let index = 0; index < samples.length; index += 1) {
        total += numeric(samples[index][fieldName], 0);
    }

    return total / samples.length;
}

function strongestPrecipitationValue(sample) {
    if (!sample) {
        return 0;
    }

    return Math.max(
        numeric(sample.precipitation, 0),
        numeric(sample.rain, 0) + numeric(sample.showers, 0),
        numeric(sample.snowfall, 0)
    );
}

function localDayKeyForApiResponse(apiResponse) {
    const current = apiResponse && apiResponse.current ? apiResponse.current : {};
    const currentTime = String(current.time || "");

    if (currentTime.length >= 10) {
        return currentTime.slice(0, 10);
    }

    const hourly = apiResponse && apiResponse.hourly ? apiResponse.hourly : {};
    const hourlyTimes = Array.isArray(hourly.time) ? hourly.time : [];

    return hourlyTimes.length > 0 ? String(hourlyTimes[0] || "").slice(0, 10) : "";
}

function collectHourlySamplesForLocalDay(apiResponse) {
    const hourly = apiResponse && apiResponse.hourly ? apiResponse.hourly : null;

    if (!hourly || !Array.isArray(hourly.time) || !Array.isArray(hourly.weather_code)) {
        return [];
    }

    const targetDayKey = localDayKeyForApiResponse(apiResponse);
    const sampleCount = Math.min(hourly.time.length, hourly.weather_code.length);
    const samples = [];

    if (!targetDayKey || sampleCount <= 0) {
        return samples;
    }

    for (let index = 0; index < sampleCount; index += 1) {
        const sampleTime = String(hourly.time[index] || "");
        const weatherCode = Math.round(numeric(hourly.weather_code[index], NaN));

        if (sampleTime.slice(0, 10) !== targetDayKey || !isFinite(weatherCode)) {
            continue;
        }

        samples.push({
            "time": sampleTime,
            "weather_code": weatherCode,
            "is_day": numeric(hourly.is_day && hourly.is_day[index], 1),
            "precipitation": numeric(hourly.precipitation && hourly.precipitation[index], 0),
            "rain": numeric(hourly.rain && hourly.rain[index], 0),
            "showers": numeric(hourly.showers && hourly.showers[index], 0),
            "snowfall": numeric(hourly.snowfall && hourly.snowfall[index], 0),
            "cloud_cover": numeric(hourly.cloud_cover && hourly.cloud_cover[index], 0),
            "relative_humidity_2m": numeric(hourly.relative_humidity_2m && hourly.relative_humidity_2m[index], 0),
            "wind_speed_10m": numeric(hourly.wind_speed_10m && hourly.wind_speed_10m[index], 0),
            "wind_direction_10m": numeric(hourly.wind_direction_10m && hourly.wind_direction_10m[index], 0),
            "kind": kindForWeatherCode(weatherCode)
        });
    }

    return samples;
}

function localHourFromTimestamp(timestampText) {
    const match = String(timestampText || "").match(/T(\d{2})/);

    return match ? Math.max(0, Math.min(23, Number(match[1]))) : -1;
}

function samplePriorityWeight(sample) {
    const hour = localHourFromTimestamp(sample && sample.time);

    if (hour >= 8 && hour <= 22) {
        return 3;
    }

    return 1;
}

function dominantKindForSamples(samples) {
    let winnerKind = CLEAR_KIND;
    let winnerCount = -1;
    let winnerScore = -1;
    const counts = {};
    const scores = {};

    for (let index = 0; index < samples.length; index += 1) {
        const sample = samples[index];
        const kind = sceneKind(sample.kind);
        const weight = samplePriorityWeight(sample);

        counts[kind] = (counts[kind] || 0) + weight;
        scores[kind] = (scores[kind] || 0) + (Math.max(0.5, severityForKind(kind)) * weight);
    }

    for (const kind in counts) {
        const count = counts[kind];
        const score = scores[kind] || 0;

        if (score > winnerScore
                || (score === winnerScore && count > winnerCount)
                || (score === winnerScore && count === winnerCount && severityForKind(kind) > severityForKind(winnerKind))) {
            winnerKind = kind;
            winnerCount = count;
            winnerScore = score;
        }
    }

    return winnerCount > 0 ? winnerKind : "";
}

function representativeWeatherCodeForSamples(samples) {
    let winnerCode = -1;
    let winnerCount = -1;
    const counts = {};

    for (let index = 0; index < samples.length; index += 1) {
        const weatherCode = Math.round(numeric(samples[index].weather_code, -1));

        if (weatherCode < 0) {
            continue;
        }

        counts[weatherCode] = (counts[weatherCode] || 0) + 1;
    }

    for (const codeKey in counts) {
        const weatherCode = Math.round(numeric(codeKey, -1));
        const count = counts[codeKey];

        if (count > winnerCount || (count === winnerCount && weatherCodePriority(weatherCode) > weatherCodePriority(winnerCode))) {
            winnerCode = weatherCode;
            winnerCount = count;
        }
    }

    return winnerCode;
}

function strongestSampleForKind(samples) {
    let winnerSample = null;
    let winnerAmount = -1;
    let winnerPriority = -1;

    for (let index = 0; index < samples.length; index += 1) {
        const sample = samples[index];
        const amount = strongestPrecipitationValue(sample);
        const priority = weatherCodePriority(sample.weather_code);

        if (amount > winnerAmount || (amount === winnerAmount && priority > winnerPriority)) {
            winnerSample = sample;
            winnerAmount = amount;
            winnerPriority = priority;
        }
    }

    return winnerSample;
}

function adjustedRepresentativeWeatherCode(kind, sample) {
    const dominantKind = sceneKind(kind);
    const sourceSample = sample || {};
    const sourceCode = Math.round(numeric(sourceSample.weather_code, -1));
    const precipitationAmount = strongestPrecipitationValue(sourceSample);

    if (dominantKind === RAIN_KIND) {
        if (precipitationAmount >= 2.8) {
            return 63;
        }

        if (precipitationAmount >= 0.6 && sourceCode >= 51 && sourceCode <= 57) {
            return 61;
        }
    }

    return sourceCode;
}

function outsideHoursSignalForSamples(samples) {
    const prioritizedSamples = samples.filter(sample => samplePriorityWeight(sample) > 1);
    const precipSamples = prioritizedSamples.filter(sample => {
        const kind = sceneKind(sample.kind);

        return (kind === RAIN_KIND || kind === SNOW_KIND || kind === THUNDERSTORM_KIND)
            && strongestPrecipitationValue(sample) > 0;
    });

    if (precipSamples.length === 0) {
        return null;
    }

    let winnerSample = null;
    let winnerScore = -1;

    for (let index = 0; index < precipSamples.length; index += 1) {
        const sample = precipSamples[index];
        const kind = sceneKind(sample.kind);
        const score = (strongestPrecipitationValue(sample) * 100) + weatherCodePriority(sample.weather_code) + (severityForKind(kind) * 1000);

        if (score > winnerScore) {
            winnerSample = sample;
            winnerScore = score;
        }
    }

    if (!winnerSample) {
        return null;
    }

    const signalKind = sceneKind(winnerSample.kind);
    const signalCode = adjustedRepresentativeWeatherCode(signalKind, winnerSample);

    return {
        "kind": signalKind,
        "label": conditionLabelForCode(signalCode),
        "weatherCode": signalCode
    };
}

function representativeCurrentDataFromHourly(apiResponse) {
    const samples = collectHourlySamplesForLocalDay(apiResponse);

    if (samples.length === 0) {
        return null;
    }

    const outsideHoursSignal = outsideHoursSignalForSamples(samples);
    const dominantKind = dominantKindForSamples(samples);
    const outsideSignalKind = outsideHoursSignal ? sceneKind(outsideHoursSignal.kind) : "";
    const visualKind = (outsideSignalKind === RAIN_KIND
            || outsideSignalKind === SNOW_KIND
            || outsideSignalKind === THUNDERSTORM_KIND)
        ? outsideSignalKind
        : dominantKind;
    const winningSamples = samples.filter(sample => sceneKind(sample.kind) === visualKind);
    const priorityWinningSamples = winningSamples.filter(sample => samplePriorityWeight(sample) > 1);
    const focusSamples = priorityWinningSamples.length > 0 ? priorityWinningSamples : winningSamples;

    if (focusSamples.length === 0) {
        return null;
    }

    const current = apiResponse && apiResponse.current ? apiResponse.current : {};
    const strongestSample = strongestSampleForKind(focusSamples);
    const representativeCurrent = {
        "time": String(current.time || focusSamples[0].time || ""),
        "weather_code": (visualKind === RAIN_KIND || visualKind === SNOW_KIND || visualKind === THUNDERSTORM_KIND)
            ? adjustedRepresentativeWeatherCode(visualKind, strongestSample)
            : representativeWeatherCodeForSamples(focusSamples),
        "is_day": numeric(current.is_day, numeric(focusSamples[0].is_day, 1))
    };

    for (let index = 0; index < DOMINANT_DAY_AVERAGE_FIELDS.length; index += 1) {
        const fieldName = DOMINANT_DAY_AVERAGE_FIELDS[index];

        if ((visualKind === RAIN_KIND || visualKind === THUNDERSTORM_KIND)
                && (fieldName === "precipitation" || fieldName === "rain" || fieldName === "showers")) {
            representativeCurrent[fieldName] = numeric(strongestSample && strongestSample[fieldName], 0);
            continue;
        }

        if (visualKind === SNOW_KIND && fieldName === "snowfall") {
            representativeCurrent[fieldName] = numeric(strongestSample && strongestSample[fieldName], 0);
            continue;
        }

        representativeCurrent[fieldName] = averageHourlyField(focusSamples, fieldName);
    }

    return {
        "currentData": representativeCurrent,
        "outsideHoursSignal": outsideHoursSignal
    };
}

function conditionLabelForCode(code) {
    const weatherCode = Math.round(numeric(code, -1));

    if (weatherCode === 0) {
        return "Clear sky";
    }

    if (weatherCode >= 1 && weatherCode <= 3) {
        return "Cloudy";
    }

    if (weatherCode === 45 || weatherCode === 48) {
        return "Fog";
    }

    if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
        return "Rain";
    }

    if ((weatherCode >= 71 && weatherCode <= 77) || weatherCode === 85 || weatherCode === 86) {
        return "Snow";
    }

    if (weatherCode >= 95) {
        return "Thunderstorm";
    }

    return "Unknown";
}

function kindForWeatherCode(code) {
    const weatherCode = Math.round(numeric(code, -1));

    if (weatherCode >= 95) {
        return THUNDERSTORM_KIND;
    }

    if ((weatherCode >= 71 && weatherCode <= 77) || weatherCode === 85 || weatherCode === 86) {
        return SNOW_KIND;
    }

    if ((weatherCode >= 51 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)) {
        return RAIN_KIND;
    }

    if (weatherCode === 45 || weatherCode === 48) {
        return FOG_KIND;
    }

    if (weatherCode >= 1 && weatherCode <= 3) {
        return CLOUDY_KIND;
    }

    return CLEAR_KIND;
}

function flowDirectionDegrees(windDirectionDegrees) {
    return ((numeric(windDirectionDegrees, 0) + 180) % 360 + 360) % 360;
}

function horizontalWindDrift(windDirectionDegrees) {
    const radians = flowDirectionDegrees(windDirectionDegrees) * Math.PI / 180;
    return clamp(Math.sin(radians), -1, 1);
}

function rainBandForCode(weatherCode, rainAmount, rainDensity) {
    if (weatherCode >= 95 || weatherCode === 65 || weatherCode === 67 || weatherCode === 82 || rainAmount >= 2.8 || rainDensity > 0.72) {
        return "downpour";
    }

    if ((weatherCode >= 51 && weatherCode <= 57) || rainAmount < 0.6 || rainDensity < 0.24) {
        return "drizzle";
    }

    return "steady";
}

function snowBandForCode(weatherCode, snowfallAmount, snowDensity) {
    if (weatherCode === 75 || snowfallAmount >= 2.2 || snowDensity > 0.72) {
        return "heavy";
    }

    if (weatherCode === 71 || weatherCode === 77 || weatherCode === 85 || snowfallAmount < 0.7 || snowDensity < 0.26) {
        return "flurries";
    }

    return "steady";
}

function applyPostRainClearing(sceneState, clearingStrength) {
    const base = normalizeSceneState(sceneState);
    const strength = clamp(numeric(clearingStrength, 0), 0, 1);

    if (strength <= 0.01 || !base.available || (base.kind !== CLEAR_KIND && base.kind !== CLOUDY_KIND)) {
        return base;
    }

    const adjusted = {};

    for (const key in base) {
        adjusted[key] = base[key];
    }

    adjusted.clearingStrength = strength;
    adjusted.conditionLabel = "Clearing after rain";
    adjusted.humidity = Math.max(base.humidity, 0.62 + (strength * 0.22));
    adjusted.humidityHaze = Math.max(base.humidityHaze, 0.18 + (strength * 0.38));
    adjusted.humidityBloom = Math.max(base.humidityBloom, 0.1 + (strength * 0.22));
    adjusted.celestialVeilOpacity = Math.max(base.celestialVeilOpacity, 0.08 + (strength * 0.1));
    adjusted.fogOpacity = Math.max(base.fogOpacity, 0.04 + (strength * 0.1));
    adjusted.fogDepth = Math.max(base.fogDepth, 0.14 + (strength * 0.24));
    adjusted.horizonFade = Math.max(base.horizonFade, 0.16 + (strength * 0.18));
    adjusted.skyDimming = Math.max(base.skyDimming, 0.08 + (strength * 0.08));
    adjusted.contrastSoftening = Math.max(base.contrastSoftening, 0.1 + (strength * 0.16));
    adjusted.sunGlowFactor = Math.min(base.sunGlowFactor, 0.84 - (strength * 0.08));
    adjusted.moonGlowFactor = Math.min(base.moonGlowFactor, 0.88 - (strength * 0.06));

    if (base.kind === CLEAR_KIND) {
        adjusted.cloudOpacity = Math.max(base.cloudOpacity, 0.14 + (strength * 0.24));
        adjusted.cloudBandCount = Math.max(base.cloudBandCount, 2 + Math.round(strength * 2));
        adjusted.cloudFamily = strength > 0.34 ? "cumulus" : "wispy";
        adjusted.cloudBreakFactor = Math.max(base.cloudBreakFactor, 0.54 + (strength * 0.22));
        adjusted.cloudShadowStrength = Math.max(base.cloudShadowStrength, 0.12 + (strength * 0.28));
        adjusted.cloudSpeed = Math.max(base.cloudSpeed, 0.12 + (strength * 0.06));
    } else {
        adjusted.cloudOpacity = clamp(Math.max(base.cloudOpacity, 0.24 + (strength * 0.18)), 0, 1);
        adjusted.cloudBandCount = Math.max(base.cloudBandCount, 3 + Math.round(strength * 2));
        adjusted.cloudFamily = (base.cloudFamily === "stratus" || base.cloudFamily === "veil") && strength > 0.24
            ? "cumulus"
            : base.cloudFamily;
        adjusted.cloudBreakFactor = Math.max(base.cloudBreakFactor, 0.42 + (strength * 0.28));
        adjusted.cloudShadowStrength = Math.max(base.cloudShadowStrength, 0.18 + (strength * 0.26));
        adjusted.cloudSpeed = Math.max(base.cloudSpeed, 0.1 + (strength * 0.06));
    }

    return normalizeSceneState(adjusted);
}

function sceneStateFromCurrentData(currentData) {
    const current = currentData || {};
    const weatherCode = Math.round(numeric(current.weather_code, -1));
    const kind = kindForWeatherCode(weatherCode);
    const precipitation = Math.max(0, numeric(current.precipitation, 0));
    const rain = Math.max(0, numeric(current.rain, 0) + numeric(current.showers, 0));
    const snowfall = Math.max(0, numeric(current.snowfall, 0));
    const cloudCover = clamp(numeric(current.cloud_cover, 0) / 100, 0, 1);
    const windSpeed = Math.max(0, numeric(current.wind_speed_10m, 0));
    const windDirectionDegrees = ((numeric(current.wind_direction_10m, 0) % 360) + 360) % 360;
    const humidity = clamp(numeric(current.relative_humidity_2m, 0) / 100, 0, 1);
    const motionStrength = clamp(windSpeed / 42, 0, 1);
    const windDrift = horizontalWindDrift(windDirectionDegrees);
    const windStrength = clamp((Math.abs(windDrift) * 0.34) + (motionStrength * 0.82), 0, 1);
    const isDay = numeric(current.is_day, 1) !== 0;

    const rainDensity = kind === THUNDERSTORM_KIND
        ? clamp(Math.max(rain, precipitation) / 5, 0.35, 1)
        : clamp(Math.max(rain, precipitation) / 5, 0, 1);
    const snowDensity = clamp(snowfall / 3, 0, 1);
    const rainBand = (kind === RAIN_KIND || kind === THUNDERSTORM_KIND) ? rainBandForCode(weatherCode, Math.max(rain, precipitation), rainDensity) : "none";
    const snowBand = kind === SNOW_KIND ? snowBandForCode(weatherCode, snowfall, snowDensity) : "none";
    const cloudOnlyOpacity = weatherCode === 1
        ? clamp(0.14 + (cloudCover * 0.18), 0.14, 0.3)
        : (weatherCode === 2
            ? clamp(0.28 + (cloudCover * 0.24), 0.32, 0.56)
            : clamp(0.52 + (cloudCover * 0.3), 0.6, 0.88));
    const cloudOpacity = kind === CLEAR_KIND
        ? cloudCover * 0.16
        : (kind === CLOUDY_KIND
            ? cloudOnlyOpacity
            : (kind === FOG_KIND
                ? clamp(0.34 + (cloudCover * 0.28), 0.36, 0.72)
                : (kind === THUNDERSTORM_KIND
                    ? clamp(0.74 + (cloudCover * 0.22), 0.78, 0.98)
                    : clamp(0.58 + (cloudCover * 0.34), 0.62, 0.96))));
    const cloudBandCount = kind === CLEAR_KIND
        ? (cloudOpacity > 0.08 ? 1 : 0)
        : (kind === CLOUDY_KIND
            ? (weatherCode === 1 ? 2 : (weatherCode === 2 ? 3 : 5))
            : (kind === FOG_KIND ? 3 : (kind === THUNDERSTORM_KIND ? 5 : (kind === RAIN_KIND ? 5 : 4))));
    const cloudFamily = kind === CLEAR_KIND
        ? "none"
        : (kind === CLOUDY_KIND
            ? (weatherCode === 1 ? "wispy" : (weatherCode === 2 ? "cumulus" : "stratus"))
            : (kind === FOG_KIND
                ? "veil"
                : (kind === THUNDERSTORM_KIND
                    ? "shelf"
                    : (kind === SNOW_KIND
                        ? (snowBand === "flurries" ? "cumulus" : "stratus")
                        : "stratus"))));
    const cloudBreakFactor = kind === CLOUDY_KIND
        ? (weatherCode === 1 ? 0.84 : (weatherCode === 2 ? 0.46 : 0.08))
        : (kind === CLEAR_KIND
            ? 0.96
            : (kind === FOG_KIND ? 0.18 : (kind === THUNDERSTORM_KIND ? 0.04 : (kind === RAIN_KIND ? 0.06 : 0.12))));
    const celestialVeilOpacity = kind === CLOUDY_KIND
        ? (weatherCode === 1 ? 0.12 : (weatherCode === 2 ? 0.2 : 0.32))
        : (kind === FOG_KIND
            ? 0.28
            : (kind === THUNDERSTORM_KIND
                ? 0.42
                : (kind === RAIN_KIND
                    ? (rainBand === "drizzle" ? 0.22 : (rainBand === "steady" ? 0.32 : 0.42))
                    : (kind === SNOW_KIND ? (snowBand === "flurries" ? 0.12 : (snowBand === "steady" ? 0.18 : 0.26)) : 0))));
    const storminess = kind === THUNDERSTORM_KIND ? clamp(0.58 + (rainDensity * 0.22) + (windSpeed / 120) + (windStrength * 0.12), 0.58, 1) : 0;
    const orbOcclusionOpacity = kind === CLOUDY_KIND
        ? (weatherCode === 1 ? 0.26 : (weatherCode === 2 ? 0.42 : 0.62))
        : (kind === FOG_KIND
            ? 0.36 + (cloudCover * 0.16)
            : (kind === THUNDERSTORM_KIND
                ? 0.72 + (storminess * 0.12)
                : (kind === RAIN_KIND
                    ? (rainBand === "drizzle" ? 0.42 : (rainBand === "steady" ? 0.58 : 0.76))
                    : (kind === SNOW_KIND
                        ? (snowBand === "flurries" ? 0.22 : (snowBand === "steady" ? 0.34 : 0.46))
                        : 0))));
    const orbOcclusionBands = kind === CLOUDY_KIND
        ? (weatherCode === 1 ? 2 : (weatherCode === 2 ? 3 : 4))
        : (kind === FOG_KIND ? 3 : (kind === THUNDERSTORM_KIND ? 5 : (kind === RAIN_KIND ? 5 : (kind === SNOW_KIND ? 4 : 0))));
    const fogOpacity = kind === FOG_KIND
        ? clamp(0.42 + (cloudCover * 0.24), 0.44, 0.84)
        : (kind === RAIN_KIND && rainBand === "downpour"
            ? clamp(0.14 + (rainDensity * 0.18), 0.14, 0.3)
            : (kind === SNOW_KIND && snowBand === "heavy"
                ? clamp(0.06 + (snowDensity * 0.08), 0.06, 0.16)
                : 0));
    const fogDepth = kind === FOG_KIND
        ? clamp(0.58 + (cloudCover * 0.2) + (windStrength * 0.08), 0.62, 0.96)
        : (kind === RAIN_KIND
            ? clamp(0.24 + (rainDensity * 0.28) + (rainBand === "downpour" ? 0.12 : 0.04), 0.22, 0.58)
            : (kind === SNOW_KIND ? clamp(0.1 + (snowDensity * 0.16) + (snowBand === "heavy" ? 0.08 : 0), 0.08, 0.36) : 0));
    const humidityHazeBase = clamp((humidity - 0.52) / 0.4, 0, 1);
    const humidityBloomBase = clamp((humidity - 0.62) / 0.32, 0, 1);
    const coolTint = kind === SNOW_KIND ? clamp(0.26 + (snowDensity * 0.34), 0.26, 0.72) : (kind === FOG_KIND ? 0.14 : 0);
    const humidityHaze = clamp(
        (humidityHazeBase * (kind === CLEAR_KIND ? 0.18 : 0.28))
        + (cloudOpacity * humidityHazeBase * 0.18)
        + (kind === FOG_KIND ? 0.22 : 0)
        + (kind === RAIN_KIND ? 0.12 : 0),
        0,
        0.84
    );
    const skyDimming = clamp(
        (cloudOpacity * 0.26)
        + (fogOpacity * 0.16)
        + (storminess * 0.28)
        + (kind === RAIN_KIND ? rainDensity * 0.18 : 0)
        + (humidityHaze * 0.1),
        0,
        0.84
    );
    const contrastSoftening = clamp(
        (cloudOpacity * 0.22)
        + (fogOpacity * 0.34)
        + (kind === SNOW_KIND ? snowDensity * 0.12 : 0)
        + (humidityHaze * 0.14)
        + (kind === RAIN_KIND ? rainDensity * 0.08 : 0),
        0,
        0.78
    );
    const starVisibilityFactor = kind === CLOUDY_KIND
        ? clamp(1 - (cloudOpacity * 0.82) - ((1 - cloudBreakFactor) * 0.18), 0.08, 1)
        : clamp(1 - (cloudOpacity * 1.08) - (fogOpacity * 0.82) - (storminess * 0.5) - (kind === RAIN_KIND ? rainDensity * 0.2 : 0), 0, 1);
    const humidityBloom = clamp(
        humidityBloomBase
        * (kind === THUNDERSTORM_KIND ? 0.22 : (kind === FOG_KIND ? 0.38 : 0.62))
        * (isDay ? 1 : 0.86)
        * (1 - (storminess * 0.38)),
        0,
        0.72
    );
    const sunGlowFactor = kind === CLOUDY_KIND
        ? clamp(1 - (cloudOpacity * 0.58) - (celestialVeilOpacity * 0.42), 0.18, 1)
        : (kind === RAIN_KIND
            ? clamp(1 - (cloudOpacity * 0.92) - (fogOpacity * 0.54) - (humidityHaze * 0.16) - (rainDensity * 0.24), 0.04, 0.42)
            : (kind === THUNDERSTORM_KIND
                ? clamp(1 - (cloudOpacity * 1.02) - (fogOpacity * 0.42) - (storminess * 0.34) - (humidityHaze * 0.16), 0.02, 0.26)
                : clamp(1 - (cloudOpacity * 0.58) - (fogOpacity * 0.38) - (storminess * 0.24) - (humidityHaze * 0.1), 0.18, 1)));
    const moonGlowFactor = kind === CLOUDY_KIND
        ? clamp(1 - (cloudOpacity * 0.36) - (celestialVeilOpacity * 0.28), 0.34, 1)
        : (kind === RAIN_KIND
            ? clamp(1 - (cloudOpacity * 0.62) - (fogOpacity * 0.34) - (humidityHaze * 0.12) - (rainDensity * 0.12), 0.18, 0.7)
            : (kind === THUNDERSTORM_KIND
                ? clamp(1 - (cloudOpacity * 0.74) - (fogOpacity * 0.32) - (storminess * 0.2) - (humidityHaze * 0.12), 0.16, 0.56)
                : clamp(1 - (cloudOpacity * 0.42) - (fogOpacity * 0.28) - (storminess * 0.12) - (humidityHaze * 0.08), 0.3, 1)));
    const horizonFade = clamp((fogOpacity * 0.58) + (rainDensity * 0.32) + (storminess * 0.24) + (kind === RAIN_KIND ? cloudOpacity * 0.08 : 0), 0, 0.9);
    const brokenShadowPeak = clamp(1 - (Math.abs(cloudOpacity - 0.44) / 0.44), 0, 1);
    const familyShadowBias = cloudFamily === "cumulus"
        ? 1
        : (cloudFamily === "wispy"
            ? 0.28
            : (cloudFamily === "stratus"
                ? 0.42
                : (cloudFamily === "shelf" ? 0.18 : 0.22)));
    const cloudShadowStrength = isDay
        ? clamp(
            ((kind === CLEAR_KIND
                ? cloudOpacity * 0.22
                : ((kind === FOG_KIND || kind === THUNDERSTORM_KIND)
                    ? 0
                    : brokenShadowPeak * familyShadowBias * (0.18 + (cloudBreakFactor * 0.46))))
                * sunGlowFactor
                * (1 - (fogOpacity * 0.66))),
            0,
            0.76
        )
        : 0;
    const lightningCadence = kind === THUNDERSTORM_KIND
        ? clamp(1.08 - (motionStrength * 0.24) - (storminess * 0.24) - (windStrength * 0.18), 0.32, 1)
        : 1;

    return normalizeSceneState({
        "available": true,
        "status": "ready",
        "kind": kind,
        "conditionLabel": conditionLabelForCode(weatherCode),
        "isDay": isDay,
        "rawWeatherCode": weatherCode,
        "observationTime": current.time || "",
        "cloudCover": cloudCover,
        "cloudOpacity": cloudOpacity,
        "cloudBandCount": cloudBandCount,
        "cloudFamily": cloudFamily,
        "cloudBreakFactor": cloudBreakFactor,
        "cloudShadowStrength": cloudShadowStrength,
        "celestialVeilOpacity": celestialVeilOpacity,
        "orbOcclusionOpacity": orbOcclusionOpacity,
        "orbOcclusionBands": orbOcclusionBands,
        "fogOpacity": fogOpacity,
        "fogDepth": fogDepth,
        "humidity": humidity,
        "humidityHaze": humidityHaze,
        "humidityBloom": humidityBloom,
        "rainAmount": Math.max(rain, precipitation),
        "rainDensity": rainDensity,
        "rainBand": rainBand,
        "snowAmount": snowfall,
        "snowDensity": snowDensity,
        "snowBand": snowBand,
        "storminess": storminess,
        "lightning": kind === THUNDERSTORM_KIND,
        "windSpeed": windSpeed,
        "windDirectionDegrees": windDirectionDegrees,
        "windDrift": windDrift,
        "motionStrength": motionStrength,
        "lightningCadence": lightningCadence,
        "skyDimming": skyDimming,
        "contrastSoftening": contrastSoftening,
        "coolTint": coolTint,
        "starVisibilityFactor": starVisibilityFactor,
        "sunGlowFactor": sunGlowFactor,
        "moonGlowFactor": moonGlowFactor,
        "horizonFade": horizonFade,
        "clearingStrength": 0,
        "cloudSpeed": clamp(0.08 + (windSpeed / 220) + (windStrength * 0.12), 0.08, 0.48)
    });
}

function sceneStateFromApiResponse(apiResponse) {
    if (!apiResponse || !apiResponse.current) {
        return normalizeSceneState({
            "status": "error",
            "conditionLabel": "Invalid response"
        });
    }

    const representativeHourlyState = representativeCurrentDataFromHourly(apiResponse);

    if (representativeHourlyState) {
        const dominantScene = sceneStateFromCurrentData(representativeHourlyState.currentData);
        const outsideHoursSignal = representativeHourlyState.outsideHoursSignal;

        dominantScene.postRainClearingEligible = false;
        dominantScene.outsideHoursSignalKind = outsideHoursSignal ? outsideHoursSignal.kind : "";
        dominantScene.outsideHoursSignalLabel = outsideHoursSignal ? outsideHoursSignal.label : "";
        return normalizeSceneState(dominantScene);
    }

    return sceneStateFromCurrentData(apiResponse.current);
}
