import QtQuick

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Time Zones")
        icon: "preferences-desktop-locale"
        source: "configTimeZones.qml"
    }
}
