import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

KCMUtils.ScrollViewKCM {
    id: page

    property bool cfg_cinematicWeather: true
    property bool cfg_hideDaytimeMoon: false
    property bool cfg_reducedMotion: false
    property int cfg_weatherIntensity: 100
    property int cfg_weatherRefreshIntervalMinutes: 15

    header: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Tune how weather looks and how often remote cards refresh.")
            wrapMode: Text.Wrap
        }
    }

    view: ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            QQC2.Switch {
                Kirigami.FormData.label: i18n("Cinematic weather:")
                checked: page.cfg_cinematicWeather
                text: checked ? i18n("Enabled") : i18n("Disabled")
                onToggled: page.cfg_cinematicWeather = checked
            }

            QQC2.Switch {
                Kirigami.FormData.label: i18n("Hide daytime moon:")
                checked: page.cfg_hideDaytimeMoon
                text: checked ? i18n("Always hide when the sun is up") : i18n("Only hide in heavier weather")
                onToggled: page.cfg_hideDaytimeMoon = checked
            }

            QQC2.Switch {
                Kirigami.FormData.label: i18n("Reduced motion:")
                checked: page.cfg_reducedMotion
                text: checked ? i18n("Prefer gentler animation") : i18n("Use full motion")
                onToggled: page.cfg_reducedMotion = checked
            }

            ColumnLayout {
                Kirigami.FormData.label: i18n("Weather intensity:")
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Slider {
                    Layout.fillWidth: true
                    from: 40
                    to: 140
                    stepSize: 5
                    value: page.cfg_weatherIntensity
                    onMoved: page.cfg_weatherIntensity = Math.round(value)
                    onValueChanged: if (!pressed) {
                        page.cfg_weatherIntensity = Math.round(value);
                    }
                }

                QQC2.Label {
                    text: i18n("%1%", page.cfg_weatherIntensity)
                    color: Kirigami.Theme.disabledTextColor
                }
            }

            ColumnLayout {
                Kirigami.FormData.label: i18n("Refresh interval:")
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.SpinBox {
                    from: 5
                    to: 60
                    stepSize: 5
                    value: page.cfg_weatherRefreshIntervalMinutes
                    editable: true
                    onValueModified: page.cfg_weatherRefreshIntervalMinutes = value
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    color: Kirigami.Theme.disabledTextColor
                    text: i18n("Remote weather is fetched from Open-Meteo for non-local cards.")
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
