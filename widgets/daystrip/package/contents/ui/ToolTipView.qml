/* Hover summary: the day at a glance, without opening the popup. */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../code/util.js" as Util

Item {
    id: tip

    property var backend

    readonly property var events: {
        var reactOnRevision = backend ? backend.calendarRevision : 0
        return backend ? backend.upcoming(3) : []
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                text: tip.backend
                      ? Util.weekday(tip.backend.now, false) + ", "
                        + tip.backend.now.getDate() + " " + Util.monthNames[tip.backend.now.getMonth()]
                      : ""
                level: 5
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        RowLayout {
            visible: tip.backend && tip.backend.weather !== null
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            WeatherGlyph {
                code: tip.backend && tip.backend.weather ? tip.backend.weather.code : 3
                day: tip.backend && tip.backend.weather ? tip.backend.weather.isDay : true
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: Kirigami.Units.iconSizes.medium
            }

            Text {
                text: {
                    if (!tip.backend || !tip.backend.weather)
                        return ""
                    var parts = [Util.temperature(tip.backend.weather.temperature, ""),
                                 Util.weatherLabel(tip.backend.weather.code)]
                    if (tip.backend.locationName)
                        parts.push(tip.backend.locationName)
                    return parts.join("  ·  ")
                }
                color: Kirigami.Theme.textColor
                opacity: 0.75
                font: Kirigami.Theme.smallFont
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Repeater {
            model: tip.events

            RowLayout {
                id: entry

                required property var modelData

                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Rectangle {
                    implicitWidth: 3
                    implicitHeight: Kirigami.Units.gridUnit * 0.9
                    radius: 1.5
                    color: entry.modelData.color
                }

                Text {
                    text: entry.modelData.allDay
                          ? "All day"
                          : Util.formatTime(entry.modelData.start, true, false)
                    color: Kirigami.Theme.textColor
                    opacity: 0.5
                    font: Kirigami.Theme.smallFont
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.6
                }

                Text {
                    text: entry.modelData.summary
                    color: Kirigami.Theme.textColor
                    opacity: 0.85
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Text {
            text: "Click for the calendar"
            color: Kirigami.Theme.textColor
            opacity: 0.4
            font: Kirigami.Theme.smallFont
            Layout.topMargin: Kirigami.Units.smallSpacing
        }
    }
}
