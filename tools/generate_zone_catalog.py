#!/usr/bin/env python3

from __future__ import annotations

import json
import pathlib
import re


ISO3166_PATH = pathlib.Path("/usr/share/zoneinfo/iso3166.tab")
ZONE1970_PATH = pathlib.Path("/usr/share/zoneinfo/zone1970.tab")
OUTPUT_PATH = pathlib.Path(__file__).resolve().parents[1] / "contents" / "ui" / "data" / "zoneCatalogData.js"

DISPLAY_NAME_OVERRIDES = {
    "AE": "UAE",
    "GB": "UK",
    "US": "USA",
}

SEARCH_ALIASES = {
    "AE": ["uae", "united arab emirates"],
    "GB": ["britain", "england", "great britain", "uk", "united kingdom"],
    "JP": ["japan"],
    "US": ["america", "u.s.", "united states", "usa"],
}


def load_country_names() -> dict[str, str]:
    country_names: dict[str, str] = {}

    for line in ISO3166_PATH.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue

        code, name = line.split("\t", 1)
        country_names[code] = name

    return country_names


def parse_coordinate_part(value: str) -> float:
    sign = -1 if value.startswith("-") else 1
    digits = value[1:]

    if len(digits) in (4, 5):
        degrees = int(digits[:-2])
        minutes = int(digits[-2:])
        seconds = 0
    elif len(digits) in (6, 7):
        degrees = int(digits[:-4])
        minutes = int(digits[-4:-2])
        seconds = int(digits[-2:])
    else:
        raise ValueError(f"Unsupported ISO6709 coordinate segment: {value}")

    decimal = degrees + (minutes / 60) + (seconds / 3600)
    return sign * decimal


def parse_coordinates(value: str) -> tuple[float, float]:
    match = re.fullmatch(r"([+-]\d{4,6})([+-]\d{5,7})", value)
    if not match:
        raise ValueError(f"Unsupported coordinate pair: {value}")

    return parse_coordinate_part(match.group(1)), parse_coordinate_part(match.group(2))


def display_country_name(country_code: str, country_names: dict[str, str]) -> str:
    return DISPLAY_NAME_OVERRIDES.get(country_code, country_names.get(country_code, country_code))


def normalized_key(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def zone_city_name(time_zone_id: str, comment: str) -> str:
    parts = time_zone_id.split("/")
    city = parts[-1].replace("_", " ")
    if city == time_zone_id:
        return comment or city
    return city


def load_zone_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    for line in ZONE1970_PATH.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue

        columns = line.split("\t")
        country_codes = columns[0].split(",")
        coordinates = columns[1]
        time_zone_id = columns[2]
        comment = columns[3] if len(columns) > 3 else ""

        latitude, longitude = parse_coordinates(coordinates)

        rows.append(
            {
                "country_codes": country_codes,
                "coordinates": coordinates,
                "time_zone_id": time_zone_id,
                "comment": comment,
                "latitude": latitude,
                "longitude": longitude,
            }
        )

    return rows


def build_entries() -> list[dict[str, object]]:
    country_names = load_country_names()
    rows = load_zone_rows()

    primary_country_counts: dict[str, int] = {}
    for row in rows:
        primary_country = row["country_codes"][0]
        primary_country_counts[primary_country] = primary_country_counts.get(primary_country, 0) + 1

    entries: list[dict[str, object]] = []
    for row in rows:
        primary_country = row["country_codes"][0]
        time_zone_id = str(row["time_zone_id"])
        comment = str(row["comment"])
        city = zone_city_name(time_zone_id, comment)
        country_name = country_names.get(primary_country, primary_country)
        country_display_name = display_country_name(primary_country, country_names)
        label = city or country_display_name

        subtitle_parts: list[str] = []
        if country_display_name and normalized_key(country_display_name) != normalized_key(label):
            subtitle_parts.append(country_display_name)
        if primary_country_counts.get(primary_country, 0) > 1 and comment:
            subtitle_parts.append(comment)
        if not subtitle_parts:
            subtitle_parts.append(time_zone_id)

        subtitle = " · ".join(subtitle_parts)

        aliases = SEARCH_ALIASES.get(primary_country, [])
        search_terms = [
            time_zone_id,
            label,
            city,
            country_display_name,
            country_name,
            primary_country,
            comment,
            *aliases,
        ]

        entries.append(
            {
                "id": time_zone_id,
                "countryCode": primary_country,
                "countryName": country_name,
                "countryDisplayName": country_display_name,
                "city": city,
                "comment": comment,
                "latitude": round(float(row["latitude"]), 6),
                "longitude": round(float(row["longitude"]), 6),
                "label": label,
                "subtitle": subtitle,
                "searchText": " ".join(term.strip().lower() for term in search_terms if term and term.strip()),
            }
        )

    entries.sort(key=lambda item: (item["label"], item["id"]))
    return entries


def main() -> None:
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(build_entries(), ensure_ascii=False, separators=(",", ":"))
    OUTPUT_PATH.write_text(f".pragma library\n\nvar entries = {payload};\n", encoding="utf-8")


if __name__ == "__main__":
    main()
