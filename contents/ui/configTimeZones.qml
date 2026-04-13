import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

import "TimeZoneCatalog.js" as TimeZoneCatalog

KCMUtils.ScrollViewKCM {
    id: page

    readonly property int rowHeight: Kirigami.Units.gridUnit * 2

    property bool syncingConfig: false
    property var cfg_selectedTimeZones: ["Local"]
    property var cfg_selectedTimeZonesDefault: ["Local"]

    ListModel {
        id: selectedZonesModel
    }

    ListModel {
        id: availableZonesModel
    }

    function selectedTimeZoneIds() {
        const ids = [];

        for (let index = 0; index < selectedZonesModel.count; index += 1) {
            ids.push(selectedZonesModel.get(index).timeZoneId);
        }

        return ids;
    }

    function syncToConfig() {
        syncingConfig = true;
        cfg_selectedTimeZones = selectedTimeZoneIds();
        syncingConfig = false;
        rebuildAvailableZones();
    }

    function resetSelectedZones(zoneIds) {
        const normalized = TimeZoneCatalog.normalizeSelection(zoneIds);

        selectedZonesModel.clear();
        for (const timeZoneId of normalized) {
            selectedZonesModel.append({
                "timeZoneId": timeZoneId
            });
        }

        rebuildAvailableZones();
    }

    function containsSelectedTimeZone(timeZoneId) {
        for (let index = 0; index < selectedZonesModel.count; index += 1) {
            if (selectedZonesModel.get(index).timeZoneId === timeZoneId) {
                return true;
            }
        }

        return false;
    }

    function rebuildAvailableZones() {
        const entries = TimeZoneCatalog.filteredEntries("", searchField.text);

        availableZonesModel.clear();
        for (const entry of entries) {
            availableZonesModel.append({
                "timeZoneId": entry.id,
                "label": entry.label,
                "subtitle": TimeZoneCatalog.subtitleForEntry(entry),
                "selected": containsSelectedTimeZone(entry.id)
            });
        }
    }

    function addTimeZone(timeZoneId) {
        if (containsSelectedTimeZone(timeZoneId)) {
            return;
        }

        selectedZonesModel.append({
            "timeZoneId": timeZoneId
        });
        syncToConfig();
    }

    function removeTimeZone(index) {
        if (selectedZonesModel.count <= 1) {
            warningMessage.text = i18n("At least one time zone must remain enabled.");
            warningMessage.visible = true;
            return;
        }

        selectedZonesModel.remove(index);
        syncToConfig();
    }

    function moveTimeZone(fromIndex, toIndex) {
        if (fromIndex < 0 || fromIndex >= selectedZonesModel.count) {
            return;
        }

        if (toIndex < 0) {
            toIndex = 0;
        }

        if (toIndex >= selectedZonesModel.count) {
            toIndex = selectedZonesModel.count - 1;
        }

        if (fromIndex === toIndex) {
            return;
        }

        selectedZonesModel.move(fromIndex, toIndex, 1);
        syncToConfig();
    }

    onCfg_selectedTimeZonesChanged: {
        if (!syncingConfig) {
            resetSelectedZones(cfg_selectedTimeZones);
        }
    }

    Component.onCompleted: resetSelectedZones(cfg_selectedTimeZones)

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Choose the time zones shown in the widget. Drag rows to change the display order.")
            wrapMode: Text.Wrap
        }

        Kirigami.InlineMessage {
            id: warningMessage

            Layout.fillWidth: true
            visible: false
            type: Kirigami.MessageType.Warning
            showCloseButton: true
        }
    }

    view: Flickable {
        id: contentFlickable

        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: contentColumn.implicitHeight

        ColumnLayout {
            id: contentColumn

            width: contentFlickable.width
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: true
                font.bold: true
                text: i18n("Configured Time Zones")
            }

            ListView {
                id: selectedZonesList

                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(rowHeight * Math.max(1, selectedZonesModel.count) + Math.max(0, selectedZonesModel.count - 1) * spacing, rowHeight)
                clip: false
                interactive: false
                model: selectedZonesModel
                spacing: Kirigami.Units.smallSpacing

                delegate: Item {
                    id: delegateRoot

                    required property int index
                    required property string timeZoneId

                    property int dragStartIndex: index

                    width: ListView.view.width
                    height: rowBackground.implicitHeight

                    Rectangle {
                        id: rowBackground

                        anchors.left: parent.left
                        anchors.right: parent.right
                        implicitHeight: page.rowHeight
                        color: dragHandler.active ? Kirigami.Theme.alternateBackgroundColor : Kirigami.Theme.backgroundColor
                        radius: Kirigami.Units.cornerRadius
                        border.color: dragHandler.active ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
                        z: dragHandler.active ? 2 : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Kirigami.Units.smallSpacing
                            anchors.rightMargin: Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing

                            Kirigami.Icon {
                                Layout.alignment: Qt.AlignVCenter
                                source: "open-menu-symbolic"
                                implicitWidth: Kirigami.Units.iconSizes.smallMedium
                                implicitHeight: implicitWidth
                                color: Kirigami.Theme.disabledTextColor
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    font.bold: true
                                    text: TimeZoneCatalog.labelFor(timeZoneId, "")
                                    elide: Text.ElideRight
                                }

                                QQC2.Label {
                                    Layout.fillWidth: true
                                    color: Kirigami.Theme.disabledTextColor
                                    text: TimeZoneCatalog.subtitleForId(timeZoneId, "")
                                    elide: Text.ElideRight
                                }
                            }

                            QQC2.ToolButton {
                                icon.name: "edit-delete"
                                text: i18n("Remove")
                                display: QQC2.AbstractButton.IconOnly
                                onClicked: page.removeTimeZone(index)
                            }
                        }

                        DragHandler {
                            id: dragHandler

                            target: rowBackground
                            xAxis.enabled: false

                            onActiveChanged: {
                                if (active) {
                                    delegateRoot.dragStartIndex = delegateRoot.index;
                                    warningMessage.visible = false;
                                    return;
                                }

                                const centerY = delegateRoot.y + rowBackground.y + (rowBackground.height / 2);
                                const proposedIndex = selectedZonesList.indexAt(Kirigami.Units.gridUnit, centerY);
                                const dropIndex = proposedIndex === -1
                                    ? (centerY < 0 ? 0 : selectedZonesModel.count - 1)
                                    : proposedIndex;

                                page.moveTimeZone(delegateRoot.dragStartIndex, dropIndex);
                                rowBackground.y = 0;
                            }
                        }
                    }
                }
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: selectedZonesModel.count === 0
                color: Kirigami.Theme.disabledTextColor
                text: i18n("No time zones selected.")
                wrapMode: Text.Wrap
            }
        }
    }

    footer: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Button {
            Layout.alignment: Qt.AlignLeft
            icon.name: "list-add"
            text: i18n("Add Time Zones…")
            onClicked: addSheet.open()
        }

        QQC2.Label {
            Layout.fillWidth: true
            color: Kirigami.Theme.disabledTextColor
            text: i18n("Use search terms like “Japan”, “UK”, “Tokyo”, or “Europe/London”.")
            wrapMode: Text.Wrap
        }
    }

    Kirigami.OverlaySheet {
        id: addSheet

        parent: page.QQC2.Overlay.overlay

        onVisibleChanged: {
            if (visible) {
                searchField.forceActiveFocus();
                rebuildAvailableZones();
            } else {
                searchField.text = "";
            }
        }

        header: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 2
                text: i18n("Add Time Zones")
                wrapMode: Text.Wrap
            }

            Kirigami.SearchField {
                id: searchField

                Layout.fillWidth: true
                onTextChanged: page.rebuildAvailableZones()
            }
        }

        footer: QQC2.DialogButtonBox {
            standardButtons: QQC2.DialogButtonBox.Close
            onRejected: addSheet.close()
        }

        ListView {
            id: availableZonesList

            clip: true
            implicitWidth: Math.max(page.width * 0.7, Kirigami.Units.gridUnit * 28)
            implicitHeight: Kirigami.Units.gridUnit * 18
            model: availableZonesModel

            delegate: QQC2.ItemDelegate {
                id: availableZoneDelegate

                required property int index
                required property string timeZoneId
                required property string label
                required property string subtitle
                required property bool selected

                width: ListView.view.width

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            font.bold: true
                            text: label
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            color: Kirigami.Theme.disabledTextColor
                            text: subtitle
                            elide: Text.ElideRight
                        }
                    }

                    QQC2.Button {
                        enabled: !selected
                        icon.name: selected ? "emblem-ok" : "list-add"
                        text: selected ? i18n("Added") : i18n("Add")
                        onClicked: {
                            page.addTimeZone(timeZoneId);
                            availableZonesModel.setProperty(availableZoneDelegate.index, "selected", true);
                        }
                    }
                }
            }
        }
    }
}
