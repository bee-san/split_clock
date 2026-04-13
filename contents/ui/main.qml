import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

import "TimeZoneCatalog.js" as TimeZoneCatalog

PlasmoidItem {
    id: root

    readonly property int outerPadding: Kirigami.Units.largeSpacing
    readonly property int cardSpacing: Kirigami.Units.smallSpacing * 2
    readonly property real preferredCardAspectRatio: 1.82
    property var configuredTimeZoneIds: ["Local"]
    readonly property int configuredTimeZoneCount: Math.max(1, configuredTimeZoneIds.length)
    readonly property var gridMetrics: calculateGridMetrics(configuredTimeZoneCount, contentGrid.width, contentGrid.height)
    readonly property int columnCount: gridMetrics.columns
    readonly property int rowCount: gridMetrics.rows
    readonly property real cardWidth: gridMetrics.cardWidth
    readonly property real cardHeight: gridMetrics.cardHeight

    function calculateGridMetrics(count, availableWidth, availableHeight) {
        const safeCount = Math.max(1, count);
        const safeWidth = Math.max(1, availableWidth);
        const safeHeight = Math.max(1, availableHeight);

        let best = {
            "columns": 1,
            "rows": safeCount,
            "cardWidth": safeWidth,
            "cardHeight": Math.max(1, (safeHeight - (cardSpacing * Math.max(0, safeCount - 1))) / safeCount),
            "score": -Infinity
        };

        for (let columns = 1; columns <= safeCount; columns += 1) {
            const rows = Math.ceil(safeCount / columns);
            const candidateWidth = (safeWidth - (cardSpacing * Math.max(0, columns - 1))) / columns;
            const candidateHeight = (safeHeight - (cardSpacing * Math.max(0, rows - 1))) / rows;

            if (candidateWidth <= 0 || candidateHeight <= 0) {
                continue;
            }

            const aspectRatio = candidateWidth / candidateHeight;
            const aspectPenalty = Math.abs(Math.log(aspectRatio / preferredCardAspectRatio));
            const area = candidateWidth * candidateHeight;
            const score = area / (1 + (aspectPenalty * 4));

            if (score > best.score) {
                best = {
                    "columns": columns,
                    "rows": rows,
                    "cardWidth": candidateWidth,
                    "cardHeight": candidateHeight,
                    "score": score
                };
            }
        }

        return best;
    }

    function syncConfiguredTimeZones() {
        configuredTimeZoneIds = TimeZoneCatalog.normalizeSelection(Plasmoid.configuration.selectedTimeZones);
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.constraintHints: Plasmoid.CanFillArea
    Plasmoid.title: i18n("Split Clock")
    toolTipMainText: i18n("Split Clock")
    toolTipSubText: i18n("%1 configured time zones", configuredTimeZoneIds.length)

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Kirigami.Units.gridUnit * 7

    Connections {
        target: Plasmoid.configuration

        function onSelectedTimeZonesChanged() {
            root.syncConfiguredTimeZones();
        }
    }

    Component.onCompleted: syncConfiguredTimeZones()

    Grid {
        id: contentGrid

        anchors.fill: parent
        anchors.margins: root.outerPadding
        columns: root.columnCount
        spacing: root.cardSpacing

        Repeater {
            model: root.configuredTimeZoneIds

            delegate: TimeCard {
                required property int index
                readonly property string zoneId: {
                    const candidate = root.configuredTimeZoneIds[index];
                    return typeof candidate === "string" && candidate.length > 0 ? candidate : "Local";
                }

                width: root.cardWidth
                height: root.cardHeight
                timeZoneId: zoneId
                entry: TimeZoneCatalog.entryFor(zoneId, "")
            }
        }
    }
}
