.pragma library
.import "data/zoneCatalogData.js" as ZoneCatalogData

let entriesCache = null;
let indexCache = null;

function localEntry() {
    return {
        id: "Local",
        label: "Local",
        subtitle: "System time zone",
        city: "Local",
        countryCode: "",
        countryDisplayName: "",
        countryName: "",
        comment: "",
        latitude: null,
        longitude: null,
        searchText: "local system timezone"
    };
}

function normalizeSearch(text) {
    return String(text || "")
        .toLowerCase()
        .replace(/[_/,+().-]+/g, " ")
        .replace(/\s+/g, " ")
        .trim();
}

function fallbackEntry(timeZoneId) {
    const parts = String(timeZoneId).split("/");
    const lastPart = parts[parts.length - 1].replace(/_/g, " ");

    return {
        id: timeZoneId,
        label: lastPart,
        subtitle: parts.length > 1 ? parts.slice(0, parts.length - 1).join(" / ").replace(/_/g, " ") : timeZoneId,
        city: lastPart,
        countryCode: "",
        countryDisplayName: "",
        countryName: "",
        comment: "",
        latitude: null,
        longitude: null,
        searchText: normalizeSearch(timeZoneId + " " + lastPart)
    };
}

function ensureLoaded(_catalogUrl) {
    if (entriesCache && indexCache) {
        return;
    }

    const completeEntries = [localEntry()].concat(ZoneCatalogData.entries || []);
    const byId = {};

    for (const entry of completeEntries) {
        byId[entry.id] = entry;
    }

    entriesCache = completeEntries;
    indexCache = byId;
}

function allEntries(catalogUrl) {
    ensureLoaded(catalogUrl);
    return entriesCache;
}

function entryFor(timeZoneId, catalogUrl) {
    ensureLoaded(catalogUrl);
    return indexCache[timeZoneId] || fallbackEntry(timeZoneId);
}

function labelFor(timeZoneId, catalogUrl) {
    return entryFor(timeZoneId, catalogUrl).label;
}

function subtitleForId(timeZoneId, catalogUrl) {
    return subtitleForEntry(entryFor(timeZoneId, catalogUrl));
}

function subtitleForEntry(entry) {
    return entry.subtitle || entry.id || "";
}

function filteredEntries(catalogUrl, queryText) {
    const query = normalizeSearch(queryText);
    const entries = allEntries(catalogUrl);

    if (!query) {
        return entries;
    }

    const filtered = [];
    for (const entry of entries) {
        const haystack = entry.searchText || normalizeSearch([entry.label, entry.subtitle, entry.id, entry.city, entry.countryName, entry.comment].join(" "));
        if (haystack.indexOf(query) !== -1) {
            filtered.push(entry);
        }
    }

    return filtered;
}

function normalizeSelection(zoneIds) {
    const unique = [];
    const seen = {};
    let source = [];

    if (Array.isArray(zoneIds)) {
        source = zoneIds;
    } else if (typeof zoneIds === "string") {
        source = zoneIds.split(",");
    } else if (zoneIds && typeof zoneIds.length === "number") {
        for (let index = 0; index < zoneIds.length; index += 1) {
            source.push(zoneIds[index]);
        }
    } else if (zoneIds !== undefined && zoneIds !== null) {
        source = [zoneIds];
    }

    for (const rawId of source) {
        const timeZoneId = String(rawId || "").trim();
        if (!timeZoneId || seen[timeZoneId]) {
            continue;
        }

        seen[timeZoneId] = true;
        unique.push(timeZoneId);
    }

    if (unique.length === 0) {
        unique.push("Local");
    }

    return unique;
}
